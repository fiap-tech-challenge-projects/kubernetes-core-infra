# =============================================================================
# FIAP Tech Challenge - Kubernetes Core Infrastructure
# =============================================================================
# Este modulo provisiona a infraestrutura base do cluster EKS na AWS
# incluindo VPC, subnets, IAM roles, e o proprio cluster Kubernetes.
# =============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  # Backend S3 para armazenamento do state
  # bucket is configured dynamically via terraform init -backend-config
  backend "s3" {
    key            = "kubernetes-core-infra/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "fiap-terraform-locks"
  }
}

# -----------------------------------------------------------------------------
# Providers
# -----------------------------------------------------------------------------

provider "aws" {
  region = var.aws_region

  # AWS Academy: Cannot use default_tags with IAM resources (iam:TagPolicy not allowed)
  # All resources that support tags have explicit tags via merge(var.common_tags, {...})
  # default_tags {
  #   tags = var.common_tags
  # }
}

# NOTE: Kubernetes and Helm providers removed to prevent chicken-and-egg problem
# during cluster creation. These providers are now configured in kubernetes-addons
# module which reads the cluster info via remote_state after cluster is created.

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

# -----------------------------------------------------------------------------
# Locals
# -----------------------------------------------------------------------------

locals {
  cluster_name = "${var.project_name}-eks-${var.environment}"

  # Seleciona as primeiras 2 AZs disponiveis
  azs = slice(data.aws_availability_zones.available.names, 0, 2)

  # Tags para recursos do EKS (necessarias para integracao com ALB)
  eks_tags = merge(var.common_tags, {
    "kubernetes.io/cluster/${local.cluster_name}" = "owned"
  })
}
