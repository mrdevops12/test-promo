resource "null_resource" "install_prom_crds" {
  # bump this to re-run CRD install when chart updates
  triggers = {
    chart_version = "56.6.2"
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOT
      set -e
      # 1) Ensure the repo exists
      helm repo add prometheus-community https://prometheus-community.github.io/helm-charts \
        || echo "repo already exists"
      helm repo update

      # 2) Render only the CRDs and apply them
      helm template prometheus-crds prometheus-community/kube-prometheus-stack \
        --version ${self.triggers.chart_version} \
        --show-only crds \
      | kubectl apply -f -
    EOT
  }
}
