terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

provider "kubernetes" {
  # assumes you have ~/.kube/config pointing at your EKS cluster
  # if you need to refresh it you can uncomment the aws CLI call below
  # config_path = "~/.kube/config"
}

variable "chart_version" {
  description = "Version of kube-prometheus-stack to deploy"
  type        = string
  default     = "69.3.0"
}

variable "aws_region" {
  description = "AWS region for EKS kubeconfig (if you auto-update)"
  type        = string
  default     = "us-east-1"
}

# 1) Create the demo-monitoring namespace
resource "kubernetes_namespace" "demo_monitoring" {
  metadata {
    name = "demo-monitoring"
  }
}

# 2) Render & apply Prometheus + Grafana via helm template (no CRDs/hooks)
resource "null_resource" "install_prometheus_via_template" {
  # re-run when chart_version or namespace name changes
  triggers = {
    version   = var.chart_version
    namespace = kubernetes_namespace.demo_monitoring.metadata[0].name
  }

  depends_on = [ kubernetes_namespace.demo_monitoring ]

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOT
      set -e

      # (Optional) refresh your kubeconfig for EKS
      # aws eks update-kubeconfig --name YOUR_CLUSTER --region ${var.aws_region}

      # 1) Add / update Helm repo
      helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || true
      helm repo update

      # 2) Render only namespace-scoped objects, skip CRDs & hooks
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

      # 3) Apply them
      kubectl apply -f /tmp/demo-prometheus.yaml

      # 4) Wait for the core workloads
      kubectl rollout status statefulset/prometheus-kube-prometheus-stack-prometheus \
        -n ${self.triggers.namespace} --timeout=10m
      kubectl rollout status deployment/kube-prometheus-stack-grafana \
        -n ${self.triggers.namespace} --timeout=10m

      echo "✅ Prometheus + Grafana deployed into namespace ${self.triggers.namespace}"
    EOT
  }
}
