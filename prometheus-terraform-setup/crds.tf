resource "null_resource" "install_prom_crds" {
  triggers = {
    chart_version = "56.6.2"
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOT
      set -e

      # Ensure repo is added
      helm repo add prometheus-community https://prometheus-community.github.io/helm-charts \
        || echo "repo already exists"
      helm repo update

      # Render only the CRDs from the chart, then apply them directly
      helm template crds prometheus-community/kube-prometheus-stack \
        --version ${self.triggers.chart_version} \
        --repo https://prometheus-community.github.io/helm-charts \
        --show-only crds | kubectl apply -f -

    EOT
  }
}
