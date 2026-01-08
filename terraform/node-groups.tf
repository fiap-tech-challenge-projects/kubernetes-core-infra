# =============================================================================
# EKS Node Groups
# =============================================================================
# Configura os managed node groups para o cluster EKS
# =============================================================================

# -----------------------------------------------------------------------------
# Node Group Principal
# -----------------------------------------------------------------------------

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project_name}-nodes-${var.environment}"
  node_role_arn   = aws_iam_role.eks_node_group.arn
  subnet_ids      = aws_subnet.private[*].id

  capacity_type  = var.node_capacity_type
  instance_types = var.node_instance_types
  disk_size      = var.node_disk_size

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    role        = "worker"
    environment = var.environment
  }

  tags = merge(local.eks_tags, {
    Name = "${var.project_name}-nodes-${var.environment}"
  })

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_container_registry_readonly,
  ]

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}

# -----------------------------------------------------------------------------
# Launch Template (Opcional - para customizacoes avancadas)
# -----------------------------------------------------------------------------

# resource "aws_launch_template" "eks_nodes" {
#   name_prefix = "${var.project_name}-nodes-"
#
#   block_device_mappings {
#     device_name = "/dev/xvda"
#
#     ebs {
#       volume_size           = var.node_disk_size
#       volume_type           = "gp3"
#       encrypted             = true
#       delete_on_termination = true
#     }
#   }
#
#   metadata_options {
#     http_endpoint               = "enabled"
#     http_tokens                 = "required" # IMDSv2
#     http_put_response_hop_limit = 2
#   }
#
#   monitoring {
#     enabled = true
#   }
#
#   tag_specifications {
#     resource_type = "instance"
#     tags = merge(local.eks_tags, {
#       Name = "${var.project_name}-node-${var.environment}"
#     })
#   }
#
#   tags = var.common_tags
# }
