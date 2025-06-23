resource "null_resource" "install_prom_crds" {
  # Change this to bump chart version in the future
  triggers = {
    chart_version = "56.6.2"
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOT
      set -e

      # 1) Add & update Prometheus community repo
      helm repo add prometheus-community https://prometheus-community.github.io/helm-charts \
        || echo "repo already exists"
      helm repo update

      # 2) Render only the CRDs from the chart and apply them
      helm template prometheus-crds prometheus-community/kube-prometheus-stack \
        --version ${self.triggers.chart_version} \
        --show-only crds \
      | kubectl apply -f -
    EOT
  }
}
