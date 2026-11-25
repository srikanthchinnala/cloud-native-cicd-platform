# ---- Build stage ----
FROM node:22-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm install --omit=dev --no-audit --no-fund
COPY src ./src

# ---- Runtime stage ----
FROM node:22-alpine
ENV NODE_ENV=production PORT=3000
# npm isn't needed at runtime: removing it shrinks the image and the CVE surface
RUN rm -rf /usr/local/lib/node_modules/npm /usr/local/bin/npm /usr/local/bin/npx
WORKDIR /app
COPY --from=build --chown=node:node /app /app
USER node
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://localhost:3000/healthz || exit 1
CMD ["node", "src/server.js"]
