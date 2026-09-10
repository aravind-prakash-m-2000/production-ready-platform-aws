variable "name" {
  type = string
}

variable "environment" {
  type = string
}

variable "oidc_provider_arn" {
  description = "EKS OIDC provider ARN for AMP ingest IRSA."
  type        = string
}

variable "oidc_provider_url" {
  description = "EKS OIDC issuer URL without https:// prefix is derived internally."
  type        = string
}

variable "grafana_authentication_providers" {
  description = "Amazon Managed Grafana identity providers."
  type        = list(string)
  default     = ["AWS_SSO"]
}

variable "log_retention_days" {
  type    = number
  default = 30
}

variable "tags" {
  type    = map(string)
  default = {}
}
