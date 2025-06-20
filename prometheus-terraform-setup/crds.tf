resource "null_resource" "vendor_prom_chart" {
  # bump this whenever you update chart version
  triggers = {
    chart_version = "56.6.2"
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOT
      set -e
      mkdir -p chart_dir
      # pull & unpack into chart_dir
      helm repo add prometheus-community https://prometheus-community.github.io/helm-charts \
        || echo "repo already exists"
      helm repo update
      helm pull prometheus-community/kube-prometheus-stack \
        --version ${self.triggers.chart_version} \
        --untar --untardir chart_dir

      # remove the built-in CRDs so Helm can’t try to install them
      rm -rf chart_dir/kube-prometheus-stack/crds
    EOT
  }
}
