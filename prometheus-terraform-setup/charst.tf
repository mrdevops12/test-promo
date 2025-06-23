resource "null_resource" "vendor_prom_chart" {
  triggers = {
    version = "69.3.0"
  }

  provisioner "local-exec" {
    interpreter = ["bash","-c"]
    command     = <<-EOT
      set -e

      # 1) Cleanup any old vendored chart
      rm -rf charts

      # 2) Ensure the repo
      helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || true
      helm repo update

      # 3) Pull & unpack the exact chart version
      mkdir -p charts
      helm pull prometheus-community/kube-prometheus-stack \
        --version ${self.triggers.version} \
        --untar --untardir charts

      # 4) Remove every CRDs folder (root + subcharts)
      find charts/kube-prometheus-stack -type d -name crds -prune -exec rm -rf {} +

      # 5) Patch out the 'crds:' section in Chart.yaml so Helm won't error
      sed -i '/^crds:/d' charts/kube-prometheus-stack/Chart.yaml
      sed -i '/^  - crds\\//d' charts/kube-prometheus-stack/Chart.yaml
    EOT
  }
}
