terraform {
  required_version = ">= 1.6.0"

  backend "s3" {
    bucket         = "CHANGE_ME-platform-tfstate"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "platform-terraform-locks"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.50.0"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = var.name
      Environment = "prod"
      Owner       = "platform-engineering"
      CostCenter  = "platform"
    }
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
}

module "vpc" {
  source = "../../modules/vpc"

  name                 = var.name
  environment          = "prod"
  cidr_block           = var.vpc_cidr
  azs                  = local.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  enable_nat_gateway   = true
  single_nat_gateway   = false
  enable_flow_logs     = true
  flow_log_retention_days = 90
}

module "eks" {
  source = "../../modules/eks"

  name                = var.name
  environment         = "prod"
  cluster_version     = var.cluster_version
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.private_subnet_ids
  public_access_cidrs = var.public_access_cidrs
  node_instance_types = ["m6i.large"]
  node_desired_size   = 3
  node_min_size       = 3
  node_max_size       = 12
  capacity_type       = "ON_DEMAND"
}

module "observability" {
  source = "../../modules/observability"

  name               = var.name
  environment        = "prod"
  oidc_provider_arn  = module.eks.oidc_provider_arn
  oidc_provider_url  = module.eks.oidc_provider_url
  log_retention_days = 90
}
