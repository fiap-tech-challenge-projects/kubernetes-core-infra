# =============================================================================
# Outputs - Kubernetes Core Infrastructure
# =============================================================================

# -----------------------------------------------------------------------------
# VPC Outputs
# -----------------------------------------------------------------------------

output "vpc_id" {
  description = "ID da VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block da VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs das subnets publicas"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs das subnets privadas"
  value       = aws_subnet.private[*].id
}

output "nat_gateway_ips" {
  description = "IPs dos NAT Gateways"
  value       = aws_eip.nat[*].public_ip
}

# -----------------------------------------------------------------------------
# EKS Outputs
# -----------------------------------------------------------------------------

output "cluster_name" {
  description = "Nome do cluster EKS"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "Endpoint do cluster EKS"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_certificate_authority" {
  description = "Certificate Authority do cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
  sensitive   = true
}

output "cluster_version" {
  description = "Versao do Kubernetes"
  value       = aws_eks_cluster.main.version
}

output "cluster_arn" {
  description = "ARN do cluster EKS"
  value       = aws_eks_cluster.main.arn
}

output "cluster_security_group_id" {
  description = "Security Group ID do cluster"
  value       = aws_security_group.eks_cluster.id
}

output "node_security_group_id" {
  description = "Security Group ID dos nodes"
  value       = aws_security_group.eks_nodes.id
}

# -----------------------------------------------------------------------------
# OIDC Outputs (para IRSA)
# -----------------------------------------------------------------------------
# AWS ACADEMY: OIDC provider cannot be created due to IAM restrictions
# In production, uncomment these outputs:
#
# output "oidc_provider_arn" {
#   description = "ARN do OIDC Provider"
#   value       = aws_iam_openid_connect_provider.eks.arn
# }
#
# output "oidc_provider_url" {
#   description = "URL do OIDC Provider"
#   value       = aws_iam_openid_connect_provider.eks.url
# }

# -----------------------------------------------------------------------------
# IAM Outputs
# -----------------------------------------------------------------------------

output "lab_role_arn" {
  description = "ARN da LabRole usada para EKS (AWS Academy)"
  value       = data.aws_iam_role.lab_role.arn
}

output "node_role_arn" {
  description = "ARN da IAM Role dos nodes (LabRole no AWS Academy)"
  value       = data.aws_iam_role.lab_role.arn
}

# NOTE: AWS Academy - These IRSA roles are not created
# In production with custom IAM, these outputs would be available:
# output "aws_lb_controller_role_arn" {
#   description = "ARN da IAM Role do AWS LB Controller"
#   value       = var.enable_aws_lb_controller ? aws_iam_role.aws_lb_controller[0].arn : null
# }
#
# output "ebs_csi_driver_role_arn" {
#   description = "ARN da IAM Role do EBS CSI Driver"
#   value       = aws_iam_role.ebs_csi_driver.arn
# }

# -----------------------------------------------------------------------------
# Namespace Outputs
# -----------------------------------------------------------------------------
# NOTE: Namespace outputs moved to kubernetes-addons module (Phase 2)
# These resources are created after cluster exists to avoid provider init issues

# -----------------------------------------------------------------------------
# Kubeconfig Command
# -----------------------------------------------------------------------------

output "kubeconfig_command" {
  description = "Comando para configurar kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.main.name}"
}

# -----------------------------------------------------------------------------
# SigNoz Access
# -----------------------------------------------------------------------------
# NOTE: SigNoz outputs moved to kubernetes-addons module (Phase 2)
# SigNoz is installed after cluster exists to avoid provider init issues

# -----------------------------------------------------------------------------
# Summary Output
# -----------------------------------------------------------------------------

output "summary" {
  description = "Resumo da infraestrutura - Fase 1 (Cluster)"
  value       = <<-EOT
    ================================================================================
    FIAP Tech Challenge - Kubernetes Core Infrastructure (Phase 1)
    ================================================================================

    Cluster EKS:
      Nome: ${aws_eks_cluster.main.name}
      Versao: ${aws_eks_cluster.main.version}
      Endpoint: ${aws_eks_cluster.main.endpoint}

    VPC:
      ID: ${aws_vpc.main.id}
      CIDR: ${aws_vpc.main.cidr_block}
      Subnets Publicas: ${join(", ", aws_subnet.public[*].id)}
      Subnets Privadas: ${join(", ", aws_subnet.private[*].id)}

    Node Group:
      Instance Types: ${join(", ", var.node_instance_types)}
      Desired: ${var.node_desired_size}
      Min: ${var.node_min_size}
      Max: ${var.node_max_size}

    Configurar kubectl:
      aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.main.name}

    Proximo passo:
      Deploy kubernetes-addons (Phase 2) para instalar namespaces, LB Controller e SigNoz
    ================================================================================
  EOT
}
