# =============================================================================
# Variaveis de Entrada - Kubernetes Core Infrastructure
# =============================================================================

# -----------------------------------------------------------------------------
# AWS Configuration
# -----------------------------------------------------------------------------

variable "aws_region" {
  description = "Regiao AWS para deploy dos recursos"
  type        = string
  default     = "us-east-1"
}

# -----------------------------------------------------------------------------
# Project Configuration
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "Nome do projeto (usado para nomear recursos)"
  type        = string
  default     = "fiap-tech-challenge"

  validation {
    condition     = can(regex("^[a-z]([a-z0-9-]*[a-z0-9])?$", var.project_name))
    error_message = "Project name deve ser lowercase com letras, numeros e hifens."
  }
}

variable "environment" {
  description = "Ambiente de deploy (development, staging, production)"
  type        = string
  default     = "development"

  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment deve ser: development, staging ou production."
  }
}

variable "common_tags" {
  description = "Tags comuns aplicadas a todos os recursos"
  type        = map(string)
  default = {
    Project   = "fiap-tech-challenge"
    Phase     = "3"
    ManagedBy = "terraform"
    Team      = "fiap-pos-grad"
  }
}

# -----------------------------------------------------------------------------
# VPC Configuration
# -----------------------------------------------------------------------------

variable "vpc_cidr" {
  description = "CIDR block para a VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR deve ser um bloco CIDR valido."
  }
}

variable "enable_nat_gateway" {
  description = "Habilitar NAT Gateway para subnets privadas"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Usar apenas um NAT Gateway (economia de custos)"
  type        = bool
  default     = true # true para AWS Academy (economia)
}

variable "enable_dns_hostnames" {
  description = "Habilitar DNS hostnames na VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Habilitar DNS support na VPC"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# EKS Configuration
# -----------------------------------------------------------------------------

variable "kubernetes_version" {
  description = "Versao do Kubernetes para o cluster EKS"
  type        = string
  default     = "1.28"

  validation {
    condition     = can(regex("^1\\.(2[5-9]|3[0-9])$", var.kubernetes_version))
    error_message = "Kubernetes version deve ser 1.25 ou superior."
  }
}

variable "cluster_endpoint_public_access" {
  description = "Habilitar acesso publico ao endpoint do cluster"
  type        = bool
  default     = true
}

variable "cluster_endpoint_private_access" {
  description = "Habilitar acesso privado ao endpoint do cluster"
  type        = bool
  default     = true
}

variable "cluster_enabled_log_types" {
  description = "Tipos de logs do cluster a serem habilitados"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

# -----------------------------------------------------------------------------
# Node Group Configuration
# -----------------------------------------------------------------------------

variable "node_instance_types" {
  description = "Tipos de instancia EC2 para os nodes"
  type        = list(string)
  default     = ["t3.medium"] # Bom custo-beneficio para AWS Academy
}

variable "node_disk_size" {
  description = "Tamanho do disco EBS dos nodes em GB"
  type        = number
  default     = 20

  validation {
    condition     = var.node_disk_size >= 20 && var.node_disk_size <= 100
    error_message = "Disk size deve ser entre 20 e 100 GB."
  }
}

variable "node_desired_size" {
  description = "Numero desejado de nodes"
  type        = number
  default     = 2

  validation {
    condition     = var.node_desired_size >= 1 && var.node_desired_size <= 10
    error_message = "Desired size deve ser entre 1 e 10."
  }
}

variable "node_min_size" {
  description = "Numero minimo de nodes"
  type        = number
  default     = 1

  validation {
    condition     = var.node_min_size >= 1 && var.node_min_size <= 5
    error_message = "Min size deve ser entre 1 e 5."
  }
}

variable "node_max_size" {
  description = "Numero maximo de nodes"
  type        = number
  default     = 4

  validation {
    condition     = var.node_max_size >= 1 && var.node_max_size <= 10
    error_message = "Max size deve ser entre 1 e 10."
  }
}

variable "node_capacity_type" {
  description = "Tipo de capacidade dos nodes (ON_DEMAND ou SPOT)"
  type        = string
  default     = "ON_DEMAND"

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.node_capacity_type)
    error_message = "Capacity type deve ser ON_DEMAND ou SPOT."
  }
}

# -----------------------------------------------------------------------------
# Application Namespace
# -----------------------------------------------------------------------------

variable "app_namespace" {
  description = "Namespace para a aplicacao principal"
  type        = string
  default     = "ftc-app"

  validation {
    condition     = can(regex("^[a-z]([a-z0-9-]*[a-z0-9])?$", var.app_namespace))
    error_message = "Namespace deve ser lowercase com letras, numeros e hifens."
  }
}

# -----------------------------------------------------------------------------
# SigNoz Configuration
# -----------------------------------------------------------------------------

variable "enable_signoz" {
  description = "Habilitar instalacao do SigNoz para observabilidade"
  type        = bool
  default     = true
}

variable "signoz_namespace" {
  description = "Namespace para o SigNoz"
  type        = string
  default     = "signoz"
}

variable "signoz_chart_version" {
  description = "Versao do Helm chart do SigNoz"
  type        = string
  default     = "0.32.0"
}

variable "signoz_storage_size" {
  description = "Tamanho do storage para ClickHouse do SigNoz"
  type        = string
  default     = "20Gi"
}

# -----------------------------------------------------------------------------
# AWS Load Balancer Controller
# -----------------------------------------------------------------------------

variable "enable_aws_lb_controller" {
  description = "Habilitar AWS Load Balancer Controller"
  type        = bool
  default     = true
}

variable "aws_lb_controller_version" {
  description = "Versao do AWS Load Balancer Controller"
  type        = string
  default     = "1.6.2"
}
