variable "name" {
  description = "Platform name prefix."
  type        = string
}

variable "environment" {
  description = "Environment name."
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for EKS."
  type        = string
  default     = "1.31"
}

variable "vpc_id" {
  description = "VPC ID for the cluster."
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs for control plane ENIs and node groups."
  type        = list(string)
}

variable "endpoint_private_access" {
  type    = bool
  default = true
}

variable "endpoint_public_access" {
  type    = bool
  default = true
}

variable "public_access_cidrs" {
  description = "CIDRs allowed to reach the public API endpoint. Restrict in production."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "node_instance_types" {
  type    = list(string)
  default = ["t3.large"]
}

variable "node_desired_size" {
  type    = number
  default = 3
}

variable "node_min_size" {
  type    = number
  default = 2
}

variable "node_max_size" {
  type    = number
  default = 6
}

variable "capacity_type" {
  description = "ON_DEMAND or SPOT."
  type        = string
  default     = "ON_DEMAND"
}

variable "tags" {
  type    = map(string)
  default = {}
}
