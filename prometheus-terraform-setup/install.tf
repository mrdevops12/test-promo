# versions.tf
terraform {
  required_providers {
    null = { source = "hashicorp/null", version = "~> 3.0" }
  }
}

# variables.tf
variable "chart_version" { default = "69.3.0" }
variable "aws_region"    { default = "us-east-1" }

# install-prometheus.tf
resource "null_resource" "install_prometheus_via_template" {
  triggers = { version = var.chart_version }

  provisioner "local-exec" {
    interpreter = ["bash","-c"]
    command     = <<-EOT
      set -e

      # (Optional) aws eks update-kubeconfig --name YOUR_CLUSTER --region ${var.aws_region}

      helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || true
      helm repo update

      helm template demo-prometheus prometheus-community/kube-prometheus-stack \
        --version ${self.triggers.version} \
        --namespace demo-monitoring --create-namespace \
        --skip-crds \
        --set global.rbac.create=false \
        --set prometheusOperator.createCustomResource=false \
        --set prometheus.service.type=LoadBalancer \
        --set grafana.enabled=true \
        --set grafana.service.type=LoadBalancer \
      > /tmp/demo-prometheus.yaml

      kubectl apply -f /tmp/demo-prometheus.yaml

      kubectl rollout status statefulset/prometheus-kube-prometheus-stack-prometheus -n demo-monitoring --timeout=10m
      kubectl rollout status deployment/kube-prometheus-stack-grafana -n demo-monitoring --timeout=10m

      echo "✅ Installed!"
    EOT
  }
}
