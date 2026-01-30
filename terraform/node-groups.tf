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
  node_role_arn   = aws_iam_role.eks_nodes.arn # Production: custom IAM role
  # AWS ACADEMY: Use data.aws_iam_role.lab_role.arn instead
  subnet_ids = aws_subnet.private[*].id

  # Use Amazon Linux 2 instead of AL2023 for better EKS bootstrap compatibility
  ami_type = "AL2_x86_64"

  capacity_type  = var.node_capacity_type
  instance_types = var.node_instance_types
  # disk_size is managed by launch template

  launch_template {
    id      = aws_launch_template.eks_nodes.id
    version = "$Latest"
  }

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

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}

# -----------------------------------------------------------------------------
# Launch Template - REQUIRED for AWS Load Balancer Controller
# -----------------------------------------------------------------------------
# Sets http_put_response_hop_limit=2 to allow IMDS access from pods
# Without this, AWS LB Controller fails with "context deadline exceeded"

resource "aws_launch_template" "eks_nodes" {
  name_prefix = "${var.project_name}-nodes-"

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.node_disk_size
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2
    http_put_response_hop_limit = 2          # CRITICAL: Required for AWS LB Controller
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(local.eks_tags, {
      Name = "${var.project_name}-node-${var.environment}"
    })
  }

  tags = var.common_tags
}
