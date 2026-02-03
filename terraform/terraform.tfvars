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

vpc_cidr           = "10.0.0.0/16"
enable_nat_gateway = true
single_nat_gateway = true # Single NAT Gateway for cost savings ($32/mo vs $96/mo)
# Production: Set to false for HA with NAT per AZ
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

node_instance_types = ["t3.small"] # 2 vCPU, 2 GB RAM (AWS credits)
# Cost: ~$15/month for 1 node (~$30 for 2 nodes)
# Minimum viable for EKS with CloudWatch + addons

node_disk_size = 30 # 30 GB for logs and container images

node_desired_size = 2 # 2 nodes for reliability (can handle pod distribution)
# Prevents "Too many pods" errors and allows rolling updates

node_min_size = 1 # Can scale down to 1 node if needed

node_max_size = 3 # Scale up to 3 nodes under load

node_capacity_type = "ON_DEMAND"
# COST OPTIMIZATION: Use "SPOT" for 70% savings (with interruption risk)

# -----------------------------------------------------------------------------
# Application Namespace
# -----------------------------------------------------------------------------

app_namespace = "ftc-app"


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
# TOTAL ACADEMY COST: ~$180/month
# - EKS Cluster: $73
# - EC2 (2x t3.medium): $60
# - RDS (db.t3.micro): $15
# - NAT Gateway (1x): $32
# - Other: ~$0 (free tier)
