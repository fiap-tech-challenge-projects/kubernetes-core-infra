# =============================================================================
# Terraform Variables - Kubernetes Core Infrastructure
# =============================================================================
# Valores otimizados para AWS Academy (economia de custos)
# =============================================================================

# -----------------------------------------------------------------------------
# AWS Configuration
# -----------------------------------------------------------------------------

aws_region = "us-east-1"

# -----------------------------------------------------------------------------
# Project Configuration
# -----------------------------------------------------------------------------

project_name = "fiap-tech-challenge"
environment  = "development"

common_tags = {
  Project   = "fiap-tech-challenge"
  Phase     = "3"
  ManagedBy = "terraform"
  Team      = "fiap-pos-grad"
}

# -----------------------------------------------------------------------------
# VPC Configuration
# -----------------------------------------------------------------------------

vpc_cidr             = "10.0.0.0/16"
enable_nat_gateway   = true
single_nat_gateway   = true # Economia: apenas 1 NAT Gateway
enable_dns_hostnames = true
enable_dns_support   = true

# -----------------------------------------------------------------------------
# EKS Configuration
# -----------------------------------------------------------------------------

kubernetes_version              = "1.31"
cluster_endpoint_public_access  = true
cluster_endpoint_private_access = true
cluster_enabled_log_types       = ["api", "audit", "authenticator"]

# -----------------------------------------------------------------------------
# Node Group Configuration
# -----------------------------------------------------------------------------

node_instance_types = ["t3.medium"] # Bom custo-beneficio
node_disk_size      = 20            # Minimo necessario
node_desired_size   = 2             # 2 nodes para HA minimo
node_min_size       = 1             # Pode escalar para 1 em idle
node_max_size       = 4             # Maximo 4 para AWS Academy
node_capacity_type  = "ON_DEMAND"   # SPOT pode ser usado para mais economia

# -----------------------------------------------------------------------------
# Application Namespace
# -----------------------------------------------------------------------------

app_namespace = "ftc-app"

# -----------------------------------------------------------------------------
# SigNoz Configuration
# -----------------------------------------------------------------------------

enable_signoz        = false  # Temporariamente desabilitado - timeout de 20min
signoz_namespace     = "signoz"
signoz_chart_version = "0.32.0"
signoz_storage_size  = "20Gi" # Ajustar conforme necessidade

# -----------------------------------------------------------------------------
# AWS Load Balancer Controller
# -----------------------------------------------------------------------------

enable_aws_lb_controller  = true
aws_lb_controller_version = "1.6.2"
