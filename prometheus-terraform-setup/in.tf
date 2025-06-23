terraform {
  required_providers {
    null       = { source = "hashicorp/null",      version = "~> 3.0" }
    kubernetes = { source = "hashicorp/kubernetes", version = "~> 2.0" }
  }
}

# ──────────────────────────────
# ▼ VARIABLE DECLARATIONS ▼
# ──────────────────────────────

variable "chart_version" {
  description = "Version of kube-prometheus-stack to deploy"
  type        = string
  default     = "69.3.0"
}

variable "aws_region" {
  description = "AWS region for EKS kubeconfig (if you auto-update via AWS CLI)"
  type        = string
  default     = "us-east-1"
}

# ──────────────────────────────
# ▼ PROVIDER CONFIGURATION ▼
# ──────────────────────────────

provider "kubernetes" {
  # Assumes ~/.kube/config is already set up for your EKS cluster
  # If you need to refresh it here, you could uncomment:
  # exec {
  #   api_version = "client.authentication.k8s.io/v1beta1"
  #   command     = "aws"
  #   args        = ["eks", "get-token", "--cluster-name", "YOUR_CLUSTER", "--region", var.aws_region]
  # }
}

# ──────────────────────────────
# ▼ NAMESPACE RESOURCE ▼
# ──────────────────────────────

resource "kubernetes_namespace" "demo_monitoring" {
  metadata {
    name = "demo-monitoring"
  }
}

# ──────────────────────────────
# ▼ HELM TEMPLATE + APPLY ▼
# ──────────────────────────────

resource "null_resource" "install_prometheus_via_template" {
  # re-run whenever chart_version or namespace changes
  triggers = {
    version   = var.chart_version
    namespace = kubernetes_namespace.demo_monitoring.metadata[0].name
  }

  # ensure namespace exists first
  depends_on = [ kubernetes_namespace.demo_monitoring ]

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOT
      set -e

      # (Optional) refresh kubeconfig for EKS, if needed:
      # aws eks update-kubeconfig --name YOUR_CLUSTER --region ${var.aws_region}

      # 1) Add / update the Prometheus Community repo
      helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || true
      helm repo update

      # 2) Render only namespace-scoped objects (skip CRDs & hooks)
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

      # 3) Apply them all
      kubectl apply -f /tmp/demo-prometheus.yaml

      # 4) Wait for Prometheus & Grafana
      kubectl rollout status statefulset/prometheus-kube-prometheus-stack-prometheus \
        -n ${self.triggers.namespace} --timeout=10m
      kubectl rollout status deployment/kube-prometheus-stack-grafana \
        -n ${self.triggers.namespace} --timeout=10m

      echo "✅ Prometheus + Grafana are running in namespace: ${self.triggers.namespace}"
    EOT
  }
}
