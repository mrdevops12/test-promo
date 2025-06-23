resource "null_resource" "install_prometheus_cli" {
  # Change this to bump chart version in the future
  triggers = {
    version = var.chart_version
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOT
      set -e

      # 1) Ensure the Prometheus Community repo is present
      helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || true
      helm repo update

      # 2) Install (or upgrade) the Prometheus stack with CRDs & hooks disabled
      helm upgrade --install demo-prometheus prometheus-community/kube-prometheus-stack \
        --version ${self.triggers.version} \
        --namespace demo-monitoring --create-namespace \
        --skip-crds \
        --disable-hooks \
        --set global.rbac.create=false \
        --set prometheusOperator.createCustomResource=false \
        --set prometheus.service.type=LoadBalancer \
        --set grafana.enabled=true \
        --set grafana.service.type=LoadBalancer \
        --timeout 10m --wait
    EOT
  }
}
