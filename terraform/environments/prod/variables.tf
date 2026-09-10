variable "name" {
  type    = string
  default = "platform"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "cluster_version" {
  type    = string
  default = "1.31"
}

variable "vpc_cidr" {
  type    = string
  default = "10.40.0.0/16"
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.40.0.0/24", "10.40.1.0/24", "10.40.2.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.40.10.0/24", "10.40.11.0/24", "10.40.12.0/24"]
}

variable "public_access_cidrs" {
  description = "Must be office/VPN CIDRs in production."
  type        = list(string)
}

variable "region_dr" {
  description = "Warm-standby region for disaster recovery."
  type        = string
  default     = "us-west-2"
}
