#!/usr/bin/env bash
# Blue/Green release:
#   1. Find the live slot from the Service selector
#   2. Deploy the new image to the idle slot
#   3. Wait for rollout + run a smoke test against the idle slot
#   4. Switch the Service selector (instant cut-over)
#   5. Keep the old slot running for fast rollback
set -euo pipefail

IMAGE="${1:?usage: blue-green-deploy.sh <image> <version>}"
VERSION="${2:-unknown}"
NS=demo

kubectl apply -f k8s/namespace.yaml
# Create the Services once. Never re-apply afterwards, or the selector would reset to blue.
if ! kubectl get svc demo-app -n "$NS" >/dev/null 2>&1; then
  kubectl apply -f k8s/service.yaml
fi

LIVE=$(kubectl get svc demo-app -n "$NS" -o jsonpath='{.spec.selector.color}' 2>/dev/null || echo "blue")
if [[ "$LIVE" == "blue" ]]; then IDLE=green; else IDLE=blue; fi

# First ever deploy: nothing is live yet, so deploy to the slot the Service already points at
if ! kubectl get deploy "demo-app-$LIVE" -n "$NS" >/dev/null 2>&1; then
  IDLE="$LIVE"
fi

echo "Live slot: $LIVE  ->  deploying $VERSION to: $IDLE"

sed -e "s|__COLOR__|$IDLE|g" -e "s|__IMAGE__|$IMAGE|g" -e "s|__VERSION__|$VERSION|g" \
  k8s/deployment.yaml | kubectl apply -f -

kubectl rollout status "deploy/demo-app-$IDLE" -n "$NS" --timeout=180s

echo "Smoke testing $IDLE slot..."
POD=$(kubectl get pod -n "$NS" -l "app=demo-app,color=$IDLE" -o jsonpath='{.items[0].status.podIP}')
kubectl run "smoke-$RANDOM" -n "$NS" --rm -i --restart=Never --image=curlimages/curl:8.11.1 -- \
  curl -fsS --max-time 5 "http://$POD:3000/healthz"

echo "Switching traffic to $IDLE"
kubectl patch svc demo-app -n "$NS" -p "{\"spec\":{\"selector\":{\"app\":\"demo-app\",\"color\":\"$IDLE\"}}}"

echo "Done. $IDLE is live. Roll back with:"
echo "  kubectl patch svc demo-app -n $NS -p '{\"spec\":{\"selector\":{\"app\":\"demo-app\",\"color\":\"$LIVE\"}}}'"
