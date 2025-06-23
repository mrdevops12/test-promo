terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

# ──────────────────────────────
# VARIABLES
# ──────────────────────────────

variable "aws_region" {
  description = "AWS region where your EKS cluster lives"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of your EKS cluster"
  type        = string
  default     = "my-eks-cluster"  # ← change me!
}

variable "chart_version" {
  description = "kube-prometheus-stack chart version"
  type        = string
  default     = "69.3.0"
}

# ──────────────────────────────
# AWS PROVIDER & EKS DATA
# ──────────────────────────────

provider "aws" {
  region = var.aws_region
}

data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name
}

# ──────────────────────────────
# KUBERNETES PROVIDER
# ──────────────────────────────

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

# ──────────────────────────────
# CREATE NAMESPACE
# ──────────────────────────────

resource "kubernetes_namespace" "demo_monitoring" {
  metadata {
    name = "demo-monitoring"
  }
}

# ──────────────────────────────
# RENDER & APPLY Helm → kubectl
# ──────────────────────────────

resource "null_resource" "install_prometheus_via_template" {
  triggers = {
    version   = var.chart_version
    namespace = kubernetes_namespace.demo_monitoring.metadata[0].name
  }

  depends_on = [ kubernetes_namespace.demo_monitoring ]

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOT
      set -e

      # 1) Add/update Prometheus Community repo
      helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || true
      helm repo update

      # 2) Render only the namespaced resources (skip CRDs, cluster-RBAC, hooks)
      helm template demo-prometheus prometheus-community/kube-prometheus-stack \
        --version ${self.triggers.version} \
        --namespace ${self.triggers.namespace} \
        --skip-crds \
        --set global.rbac.create=false \
        --set prometheusOperator.createCustomResource=false \
        --set prometheus.service.type=LoadBalancer \
        --set grafana.enabled=true \
        --set grafana.service.type=LoadBalancer \
      > /tmp/demo-prometheus.yaml

      # 3) Apply it
      kubectl apply -f /tmp/demo-prometheus.yaml

      # 4) Wait for Prometheus (by label) & Grafana (by label)
      kubectl rollout status statefulset -l app.kubernetes.io/name=prometheus \
        -n ${self.triggers.namespace} --timeout=10m

      kubectl rollout status deployment -l app.kubernetes.io/name=grafana \
        -n ${self.triggers.namespace} --timeout=10m

      echo "✅ Prometheus + Grafana are running in namespace ${self.triggers.namespace}"
    EOT
  }
}
