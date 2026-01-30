# =============================================================================
# IAM Roles - Production Version (Non-AWS Academy)
# =============================================================================
# Creates custom IAM roles with least-privilege permissions for EKS cluster
# and worker nodes.
#
# AWS ACADEMY USERS: See commented section below for LabRole workaround
# =============================================================================

# -----------------------------------------------------------------------------
# EKS Cluster IAM Role
# -----------------------------------------------------------------------------
resource "aws_iam_role" "eks_cluster" {
  name = "${var.project_name}-eks-cluster-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-eks-cluster-role-${var.environment}"
    }
  )
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster.name
}

# -----------------------------------------------------------------------------
# EKS Node Group IAM Role
# -----------------------------------------------------------------------------
resource "aws_iam_role" "eks_nodes" {
  name = "${var.project_name}-eks-nodes-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-eks-nodes-role-${var.environment}"
    }
  )
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "ecr_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_nodes.name
}

# EBS CSI Driver Policy - DISABLED (not using EBS CSI addon)
# If enabling EBS CSI addon later, uncomment this:
# resource "aws_iam_role_policy_attachment" "ebs_csi_policy" {
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
#   role       = aws_iam_role.eks_nodes.name
# }

# -----------------------------------------------------------------------------
# OIDC Provider for IRSA (IAM Roles for Service Accounts)
# -----------------------------------------------------------------------------
data "tls_certificate" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-eks-oidc-${var.environment}"
    }
  )
}

# -----------------------------------------------------------------------------
# AWS Load Balancer Controller IAM Role (IRSA)
# -----------------------------------------------------------------------------
resource "aws_iam_role" "aws_lb_controller" {
  name = "${var.project_name}-aws-lb-controller-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
          "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-aws-lb-controller-role-${var.environment}"
    }
  )
}

resource "aws_iam_policy" "aws_lb_controller" {
  name        = "${var.project_name}-aws-lb-controller-${var.environment}"
  description = "IAM policy for AWS Load Balancer Controller"

  policy = file("${path.module}/policies/aws-lb-controller-policy.json")

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-aws-lb-controller-policy-${var.environment}"
    }
  )
}

resource "aws_iam_role_policy_attachment" "aws_lb_controller" {
  policy_arn = aws_iam_policy.aws_lb_controller.arn
  role       = aws_iam_role.aws_lb_controller.name
}

# -----------------------------------------------------------------------------
# EBS CSI Driver IAM Role (IRSA) - OPTIONAL
# -----------------------------------------------------------------------------
# Uncomment if you want dedicated IRSA for EBS CSI Driver instead of node role

# resource "aws_iam_role" "ebs_csi_driver" {
#   name = "${var.project_name}-ebs-csi-driver-${var.environment}"
#
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Effect = "Allow"
#       Principal = {
#         Federated = aws_iam_openid_connect_provider.eks.arn
#       }
#       Action = "sts:AssumeRoleWithWebIdentity"
#       Condition = {
#         StringEquals = {
#           "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
#           "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud" = "sts.amazonaws.com"
#         }
#       }
#     }]
#   })
#
#   tags = merge(
#     local.common_tags,
#     {
#       Name = "${var.project_name}-ebs-csi-driver-role-${var.environment}"
#     }
#   )
# }
#
# resource "aws_iam_role_policy_attachment" "ebs_csi_driver" {
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
#   role       = aws_iam_role.ebs_csi_driver.name
# }

# =============================================================================
# AWS ACADEMY WORKAROUND (COMMENTED OUT)
# =============================================================================
# The section below is for AWS Academy environments ONLY.
# AWS Academy does not allow custom IAM role creation.
# Instead, use the pre-existing LabRole.
#
# TO USE AWS ACADEMY VERSION:
# 1. Comment out ALL code above (lines 1-213)
# 2. Uncomment the code below
# 3. Update eks.tf to use data.aws_iam_role.lab_role.arn
# 4. Update node-groups.tf to use data.aws_iam_role.lab_role.arn
# 5. Disable IRSA in kubernetes-addons (no OIDC provider)
# =============================================================================

# # -----------------------------------------------------------------------------
# # AWS Academy - LabRole Data Source
# # -----------------------------------------------------------------------------
# # AWS ACADEMY LIMITATION: Cannot create custom IAM roles
# # Use pre-existing LabRole with broad permissions
# #
# # SECURITY WARNING: LabRole violates least-privilege principle
# # All EKS resources (cluster, nodes, pods) share same role
# # In production AWS, use custom roles above
#
# data "aws_iam_role" "lab_role" {
#   name = "LabRole"
# }
#
# # -----------------------------------------------------------------------------
# # Policy Attachments (NOT POSSIBLE in AWS Academy)
# # -----------------------------------------------------------------------------
# # AWS ACADEMY LIMITATION: Cannot attach/detach policies from LabRole
# # LabRole already has necessary permissions in AWS Academy environment
# #
# # In production AWS, attach these policies to custom node role:
# # - AmazonEKSWorkerNodePolicy
# # - AmazonEKS_CNI_Policy
# # - AmazonEC2ContainerRegistryReadOnly
# # - AmazonEBSCSIDriverPolicy (if using EBS CSI)
#
# # -----------------------------------------------------------------------------
# # OIDC Provider (NOT POSSIBLE in AWS Academy)
# # -----------------------------------------------------------------------------
# # AWS ACADEMY LIMITATION: Cannot create OIDC providers
# # Result: No IRSA support, all pods use node role permissions
# #
# # In production AWS, OIDC provider enables fine-grained service account permissions
# # Uncomment the OIDC and IRSA sections above for production
