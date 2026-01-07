# =============================================================================
# Kubernetes Addons
# =============================================================================
# Configura addons adicionais: AWS Load Balancer Controller, SigNoz
# =============================================================================

# -----------------------------------------------------------------------------
# Namespace para Aplicacao - Staging (Homologacao)
# -----------------------------------------------------------------------------

resource "kubernetes_namespace" "staging" {
  metadata {
    name = "${var.app_namespace}-staging"

    labels = {
      name        = "${var.app_namespace}-staging"
      environment = "staging"
      managed-by  = "terraform"
    }
  }

  depends_on = [aws_eks_node_group.main]
}

# -----------------------------------------------------------------------------
# Namespace para Aplicacao - Production
# -----------------------------------------------------------------------------

resource "kubernetes_namespace" "production" {
  metadata {
    name = "${var.app_namespace}-production"

    labels = {
      name        = "${var.app_namespace}-production"
      environment = "production"
      managed-by  = "terraform"
    }
  }

  depends_on = [aws_eks_node_group.main]
}

# -----------------------------------------------------------------------------
# AWS Load Balancer Controller
# -----------------------------------------------------------------------------

resource "helm_release" "aws_lb_controller" {
  count = var.enable_aws_lb_controller ? 1 : 0

  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = var.aws_lb_controller_version
  namespace  = "kube-system"

  set {
    name  = "clusterName"
    value = aws_eks_cluster.main.name
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.aws_lb_controller[0].arn
  }

  set {
    name  = "region"
    value = var.aws_region
  }

  set {
    name  = "vpcId"
    value = aws_vpc.main.id
  }

  depends_on = [
    aws_eks_node_group.main,
    aws_iam_role_policy_attachment.aws_lb_controller,
  ]
}

# -----------------------------------------------------------------------------
# Metrics Server (para HPA)
# -----------------------------------------------------------------------------

resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = "3.11.0"
  namespace  = "kube-system"

  set {
    name  = "args[0]"
    value = "--kubelet-insecure-tls"
  }

  depends_on = [aws_eks_node_group.main]
}

# -----------------------------------------------------------------------------
# SigNoz Namespace
# -----------------------------------------------------------------------------

resource "kubernetes_namespace" "signoz" {
  count = var.enable_signoz ? 1 : 0

  metadata {
    name = var.signoz_namespace

    labels = {
      name        = var.signoz_namespace
      purpose     = "observability"
      managed-by  = "terraform"
    }
  }

  depends_on = [aws_eks_node_group.main]
}

# -----------------------------------------------------------------------------
# SigNoz via Helm
# -----------------------------------------------------------------------------

resource "helm_release" "signoz" {
  count = var.enable_signoz ? 1 : 0

  name       = "signoz"
  repository = "https://charts.signoz.io"
  chart      = "signoz"
  version    = var.signoz_chart_version
  namespace  = var.signoz_namespace

  # Valores customizados para AWS Academy (recursos limitados)
  values = [
    yamlencode({
      # ClickHouse configuration
      clickhouse = {
        persistence = {
          enabled = true
          size    = var.signoz_storage_size
        }
        resources = {
          requests = {
            cpu    = "100m"
            memory = "256Mi"
          }
          limits = {
            cpu    = "500m"
            memory = "1Gi"
          }
        }
      }

      # Query Service
      queryService = {
        resources = {
          requests = {
            cpu    = "100m"
            memory = "256Mi"
          }
          limits = {
            cpu    = "500m"
            memory = "512Mi"
          }
        }
      }

      # Frontend
      frontend = {
        resources = {
          requests = {
            cpu    = "50m"
            memory = "128Mi"
          }
          limits = {
            cpu    = "200m"
            memory = "256Mi"
          }
        }
      }

      # OTel Collector
      otelCollector = {
        resources = {
          requests = {
            cpu    = "100m"
            memory = "256Mi"
          }
          limits = {
            cpu    = "500m"
            memory = "512Mi"
          }
        }
      }

      # Alertmanager
      alertmanager = {
        enabled = true
        resources = {
          requests = {
            cpu    = "50m"
            memory = "64Mi"
          }
          limits = {
            cpu    = "100m"
            memory = "128Mi"
          }
        }
      }
    })
  ]

  depends_on = [
    kubernetes_namespace.signoz,
    aws_eks_addon.ebs_csi,
  ]
}

# -----------------------------------------------------------------------------
# StorageClass para GP3 (performance melhor)
# -----------------------------------------------------------------------------

resource "kubernetes_storage_class" "gp3" {
  metadata {
    name = "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy         = "Delete"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true

  parameters = {
    type      = "gp3"
    encrypted = "true"
  }

  depends_on = [aws_eks_addon.ebs_csi]
}

# Remover default da gp2
resource "kubernetes_annotations" "gp2_non_default" {
  api_version = "storage.k8s.io/v1"
  kind        = "StorageClass"
  metadata {
    name = "gp2"
  }
  annotations = {
    "storageclass.kubernetes.io/is-default-class" = "false"
  }

  depends_on = [kubernetes_storage_class.gp3]
}
