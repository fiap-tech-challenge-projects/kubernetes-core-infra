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
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  # Backend S3 para armazenamento do state
  backend "s3" {
    bucket         = "fiap-tech-challenge-tf-state-118735037876"
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

  default_tags {
    tags = var.common_tags
  }
}

# Kubernetes provider configurado apos criacao do cluster
provider "kubernetes" {
  host                   = aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority[0].data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.main.name]
  }
}

# Helm provider para instalacao de charts
provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.main.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority[0].data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.main.name]
    }
  }
}

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
