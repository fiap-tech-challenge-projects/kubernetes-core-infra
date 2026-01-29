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
output "oidc_provider_arn" {
  description = "ARN do OIDC Provider for IRSA"
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "oidc_provider_url" {
  description = "URL do OIDC Provider (without https://)"
  value       = replace(aws_iam_openid_connect_provider.eks.url, "https://", "")
}

# -----------------------------------------------------------------------------
# IAM Outputs
# -----------------------------------------------------------------------------

output "eks_cluster_role_arn" {
  description = "ARN da IAM Role do EKS cluster"
  value       = aws_iam_role.eks_cluster.arn
}

output "eks_cluster_role_name" {
  description = "Nome da IAM Role do EKS cluster"
  value       = aws_iam_role.eks_cluster.name
}

output "node_role_arn" {
  description = "ARN da IAM Role dos worker nodes"
  value       = aws_iam_role.eks_nodes.arn
}

output "node_role_name" {
  description = "Nome da IAM Role dos worker nodes"
  value       = aws_iam_role.eks_nodes.name
}

output "aws_lb_controller_role_arn" {
  description = "ARN da IAM Role do AWS Load Balancer Controller (IRSA)"
  value       = aws_iam_role.aws_lb_controller.arn
}

output "aws_lb_controller_role_name" {
  description = "Nome da IAM Role do AWS Load Balancer Controller"
  value       = aws_iam_role.aws_lb_controller.name
}

# Uncomment if using dedicated IRSA for EBS CSI Driver (currently using node role)
# output "ebs_csi_driver_role_arn" {
#   description = "ARN da IAM Role do EBS CSI Driver (IRSA)"
#   value       = aws_iam_role.ebs_csi_driver.arn
# }

# =============================================================================
# AWS ACADEMY OUTPUTS (COMMENTED OUT)
# =============================================================================
# For AWS Academy, use these outputs instead:
#
# output "lab_role_arn" {
#   description = "ARN da LabRole usada para EKS (AWS Academy)"
#   value       = data.aws_iam_role.lab_role.arn
# }
#
# output "node_role_arn" {
#   description = "ARN da IAM Role dos nodes (LabRole no AWS Academy)"
#   value       = data.aws_iam_role.lab_role.arn
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
