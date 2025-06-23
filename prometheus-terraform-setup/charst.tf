resource "null_resource" "vendor_prom_chart" {
  # ← bump this to upgrade chart version
  triggers = {
    version = "69.3.0"
  }

  provisioner "local-exec" {
    interpreter = ["bash","-c"]
    command     = <<-EOT
      set -e

      # 1) Clean up any old vendored chart
      rm -rf ./charts

      # 2) Ensure the upstream repo is known
      helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || true
      helm repo update

      # 3) Pull & unpack that exact version
      mkdir -p charts
      helm pull prometheus-community/kube-prometheus-stack \
        --version ${self.triggers.version} \
        --untar --untardir charts

      # 4) Strip out every CRDs folder (root + subcharts)
      find charts/kube-prometheus-stack -type d -name crds -prune -exec rm -rf {} +

      # 5) Also remove any standalone CRD templates or hooks
      grep -Rl "helm.sh/hook:.*crd-install" charts/kube-prometheus-stack \
        | xargs -r rm -f
    EOT
  }
}
