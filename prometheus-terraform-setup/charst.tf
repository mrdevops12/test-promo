resource "null_resource" "vendor_prom_chart" {
  # bump this to upgrade chart version
  triggers = { version = "69.3.0" }

  provisioner "local-exec" {
    interpreter = ["bash","-c"]
    command     = <<-EOT
      set -e

      # 1) Clean any previous chart
      rm -rf charts

      # 2) Ensure repo
      helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || true
      helm repo update

      # 3) Pull & unpack the exact chart
      mkdir -p charts
      helm pull prometheus-community/kube-prometheus-stack \
        --version ${self.triggers.version} \
        --untar --untardir charts

      # 4) Remove all crds/ directories (root & subcharts)
      find charts/kube-prometheus-stack -type d -name crds -prune -exec rm -rf {} +

      # 5) Strip out the 'crds:' block in Chart.yaml
      #    so Helm doesn’t complain the folder is missing
      sed -i.bak \
        -e '/^crds:/d' \
        -e '/^[[:space:]]\\+- crds\\//d' \
        charts/kube-prometheus-stack/Chart.yaml \
      && rm charts/kube-prometheus-stack/Chart.yaml.bak

      echo "✅ Vendored chart is patched and ready."
    EOT
  }
}
