# =============================================================================
# EKS - Elastic Kubernetes Service
# =============================================================================
# Configura o cluster EKS e seus componentes
# =============================================================================

# -----------------------------------------------------------------------------
# EKS Cluster
# -----------------------------------------------------------------------------

resource "aws_eks_cluster" "main" {
  name     = local.cluster_name
  version  = var.kubernetes_version
  role_arn = aws_iam_role.eks_cluster.arn # Production: custom IAM role
  # AWS ACADEMY: Use data.aws_iam_role.lab_role.arn instead

  vpc_config {
    subnet_ids              = concat(aws_subnet.public[*].id, aws_subnet.private[*].id)
    endpoint_public_access  = var.cluster_endpoint_public_access
    endpoint_private_access = var.cluster_endpoint_private_access
    security_group_ids      = [aws_security_group.eks_cluster.id]
  }

  enabled_cluster_log_types = var.cluster_enabled_log_types

  # Encryption configuration
  encryption_config {
    provider {
      key_arn = aws_kms_key.eks.arn
    }
    resources = ["secrets"]
  }

  tags = local.eks_tags

  depends_on = [
    aws_cloudwatch_log_group.eks,
  ]
}

# -----------------------------------------------------------------------------
# KMS Key para Encryption
# -----------------------------------------------------------------------------

resource "aws_kms_key" "eks" {
  description             = "KMS key for EKS cluster ${local.cluster_name}"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-eks-kms-${var.environment}"
  })
}

resource "aws_kms_alias" "eks" {
  name          = "alias/${var.project_name}-eks-${var.environment}"
  target_key_id = aws_kms_key.eks.key_id
}

# -----------------------------------------------------------------------------
# CloudWatch Log Group para EKS
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "eks" {
  name              = "/aws/eks/${local.cluster_name}/cluster"
  retention_in_days = 30 # Production: 30 days for troubleshooting
  # AWS ACADEMY: Use retention_in_days = 7 for cost optimization

  tags = var.common_tags
}

# -----------------------------------------------------------------------------
# Security Group - EKS Cluster
# -----------------------------------------------------------------------------

resource "aws_security_group" "eks_cluster" {
  name        = "${var.project_name}-eks-cluster-sg-${var.environment}"
  description = "Security group for EKS cluster control plane"
  vpc_id      = aws_vpc.main.id

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-eks-cluster-sg-${var.environment}"
  })
}

resource "aws_security_group_rule" "cluster_ingress_nodes" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster.id
  source_security_group_id = aws_security_group.eks_nodes.id
  description              = "Allow nodes to communicate with cluster API"
}

resource "aws_security_group_rule" "cluster_egress_nodes" {
  type                     = "egress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster.id
  source_security_group_id = aws_security_group.eks_nodes.id
  description              = "Allow cluster to communicate with nodes"
}

# -----------------------------------------------------------------------------
# Security Group - EKS Nodes
# -----------------------------------------------------------------------------

resource "aws_security_group" "eks_nodes" {
  name        = "${var.project_name}-eks-nodes-sg-${var.environment}"
  description = "Security group for EKS worker nodes"
  vpc_id      = aws_vpc.main.id

  tags = merge(local.eks_tags, {
    Name = "${var.project_name}-eks-nodes-sg-${var.environment}"
  })
}

# Node to Node communication
resource "aws_security_group_rule" "nodes_internal" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1"
  security_group_id        = aws_security_group.eks_nodes.id
  source_security_group_id = aws_security_group.eks_nodes.id
  description              = "Allow nodes to communicate with each other"
}

# Cluster to Nodes
resource "aws_security_group_rule" "nodes_cluster_ingress" {
  type                     = "ingress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_nodes.id
  source_security_group_id = aws_security_group.eks_cluster.id
  description              = "Allow cluster to communicate with nodes"
}

# Nodes to Cluster API
resource "aws_security_group_rule" "nodes_cluster_egress" {
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_nodes.id
  source_security_group_id = aws_security_group.eks_cluster.id
  description              = "Allow nodes to communicate with cluster API"
}

# Nodes to Internet
resource "aws_security_group_rule" "nodes_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.eks_nodes.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow nodes outbound access"
}

# CoreDNS
resource "aws_security_group_rule" "nodes_dns_tcp" {
  type                     = "ingress"
  from_port                = 53
  to_port                  = 53
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_nodes.id
  source_security_group_id = aws_security_group.eks_nodes.id
  description              = "Allow DNS TCP"
}

resource "aws_security_group_rule" "nodes_dns_udp" {
  type                     = "ingress"
  from_port                = 53
  to_port                  = 53
  protocol                 = "udp"
  security_group_id        = aws_security_group.eks_nodes.id
  source_security_group_id = aws_security_group.eks_nodes.id
  description              = "Allow DNS UDP"
}

# -----------------------------------------------------------------------------
# EKS Addons
# -----------------------------------------------------------------------------

# VPC CNI
resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "vpc-cni"

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = var.common_tags
}

# CoreDNS
resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "coredns"

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = var.common_tags

  depends_on = [aws_eks_node_group.main]
}

# kube-proxy
resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "kube-proxy"

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = var.common_tags
}

# EBS CSI Driver (with node role permissions)
# NOTE: Using node role instead of dedicated IRSA for simplicity
# To use dedicated IRSA: uncomment ebs_csi_driver role in iam.tf and set service_account_role_arn below
resource "aws_eks_addon" "ebs_csi" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "aws-ebs-csi-driver"

  # Production: Uses node role (aws_iam_role.eks_nodes has AmazonEBSCSIDriverPolicy attached)
  # For dedicated IRSA: service_account_role_arn = aws_iam_role.ebs_csi_driver.arn

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = var.common_tags

  depends_on = [aws_eks_node_group.main]
}

# =============================================================================
# AWS ACADEMY VERSION (COMMENTED OUT)
# =============================================================================
# EBS CSI Driver causes timeout issues in AWS Academy without proper IRSA support.
# If needed in Academy, install manually with LabRole permissions:
#
# # EBS CSI Driver - DISABLED for AWS Academy
# # resource "aws_eks_addon" "ebs_csi" {
# #   cluster_name = aws_eks_cluster.main.name
# #   addon_name   = "aws-ebs-csi-driver"
# #   # Uses LabRole (no IRSA available in Academy)
# #
# #   resolve_conflicts_on_create = "OVERWRITE"
# #   resolve_conflicts_on_update = "OVERWRITE"
# #
# #   tags = var.common_tags
# #
# #   depends_on = [aws_eks_node_group.main]
# # }
