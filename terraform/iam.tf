# =============================================================================
# IAM - AWS Academy Compatible Version
# =============================================================================
# Esta versao usa a LabRole existente do AWS Academy ao inves de criar
# roles customizadas, contornando as restricoes de IAM do ambiente Academy.
#
# IMPORTANTE: Esta e uma solucao temporaria para AWS Academy.
# Em producao real, usar roles dedicadas com least-privilege.
# =============================================================================

# -----------------------------------------------------------------------------
# Data Source - LabRole Existente do AWS Academy
# -----------------------------------------------------------------------------

data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

# -----------------------------------------------------------------------------
# Attach Required EKS Node Policies to LabRole
# -----------------------------------------------------------------------------
# Note: These attachments are idempotent - if already attached, no error occurs

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = data.aws_iam_role.lab_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = data.aws_iam_role.lab_role.name
}

resource "aws_iam_role_policy_attachment" "ecr_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = data.aws_iam_role.lab_role.name
}

# -----------------------------------------------------------------------------
# OIDC Provider para Service Accounts (IRSA)
# -----------------------------------------------------------------------------
# AWS ACADEMY LIMITATION: Cannot create OIDC providers
# In production AWS, uncomment this to enable IRSA:
#
# data "tls_certificate" "eks" {
#   url = aws_eks_cluster.main.identity[0].oidc[0].issuer
# }
#
# resource "aws_iam_openid_connect_provider" "eks" {
#   client_id_list  = ["sts.amazonaws.com"]
#   thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
#   url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
#
#   tags = var.common_tags
# }
