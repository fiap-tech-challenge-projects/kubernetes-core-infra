# =============================================================================
# Terraform Variables - Kubernetes Core Infrastructure
# =============================================================================
# Production-grade configuration for non-Academy AWS accounts
# See commented sections below for AWS Academy cost-optimized values
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
single_nat_gateway   = false  # Production: HA with NAT per AZ
# AWS ACADEMY: Set to true for cost savings (single NAT = $32/mo vs $96/mo)
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
# Node Group Configuration - Production
# -----------------------------------------------------------------------------

node_instance_types = ["t3.large"]  # Production: 2 vCPU, 8 GB RAM per node
# AWS ACADEMY: Use ["t3.medium"] for cost savings (2 vCPU, 4 GB RAM)

node_disk_size = 50  # Production: 50 GB per node
# AWS ACADEMY: Use 20 for minimum required disk space

node_desired_size = 3   # Production: 3 nodes across 3 AZs
# AWS ACADEMY: Use 2 for minimum HA

node_min_size = 2  # Production: always 2 nodes minimum
# AWS ACADEMY: Use 1 to allow scaling down in idle

node_max_size = 10  # Production: scale up to 10 nodes
# AWS ACADEMY: Use 4 to stay within credit limits

node_capacity_type = "ON_DEMAND"
# COST OPTIMIZATION: Use "SPOT" for 70% savings (with interruption risk)

# -----------------------------------------------------------------------------
# Application Namespace
# -----------------------------------------------------------------------------

app_namespace = "ftc-app"

# -----------------------------------------------------------------------------
# SigNoz Configuration - Production
# -----------------------------------------------------------------------------

enable_signoz = true  # Production: Full observability enabled
# AWS ACADEMY: Set to false to avoid 20-minute timeout and save resources

signoz_namespace     = "signoz"
signoz_chart_version = "0.32.0"
signoz_storage_size  = "20Gi"  # Adjust based on log volume

# -----------------------------------------------------------------------------
# AWS Load Balancer Controller
# -----------------------------------------------------------------------------

enable_aws_lb_controller  = true
aws_lb_controller_version = "1.6.2"

# =============================================================================
# AWS ACADEMY COST-OPTIMIZED VALUES (COMMENTED OUT)
# =============================================================================
# Use these values for AWS Academy to stay within $50-100/month credits:
#
# # VPC
# single_nat_gateway = true  # $32/mo (vs $96/mo for 3x NAT)
#
# # Nodes
# node_instance_types = ["t3.medium"]  # $60/mo for 2 nodes (vs $120/mo for t3.large)
# node_disk_size      = 20             # Minimum required
# node_desired_size   = 2              # Minimum HA
# node_min_size       = 1              # Allow scale-down to 1
# node_max_size       = 4              # Credit limit
#
# # Observability
# enable_signoz = false  # Avoid timeout and save ~2GB RAM
#
# TOTAL ACADEMY COST: ~$180/month
# - EKS Cluster: $73
# - EC2 (2x t3.medium): $60
# - RDS (db.t3.micro): $15
# - NAT Gateway (1x): $32
# - Other: ~$0 (free tier)
