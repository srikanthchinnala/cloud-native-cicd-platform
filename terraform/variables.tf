variable "project_name" {
  description = "Name prefix for all resources"
  type        = string
  default     = "cloud-native-cicd"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-2" # London
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "cluster_version" {
  description = "EKS Kubernetes version"
  type        = string
  default     = "1.31"
}

variable "node_instance_types" {
  description = "Instance types for the EKS managed node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  type    = number
  default = 2
}

variable "github_repo" {
  description = "GitHub repo allowed to deploy via OIDC, in owner/name form"
  type        = string
  default     = "srikanthchinnala/cloud-native-cicd-platform"
}
