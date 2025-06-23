resource "null_resource" "vendor_prom_chart" {
  # bump this when you want to upgrade chart version
  triggers = {
    version = "56.6.2"
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOT
      set -e

      # clean up any past vendored chart
      rm -rf ./charts

      # make the folder
      mkdir -p charts

      # ensure the repo is present
      helm repo add prometheus-community https://prometheus-community.github.io/helm-charts \
        || true
      helm repo update

      # pull & unpack the exact chart version
      helm pull prometheus-community/kube-prometheus-stack \
        --version ${self.triggers.version} \
        --untar --untardir charts

      # remove its CRDs folder (and thus all the crd-install hooks)
      rm -rf charts/kube-prometheus-stack/crds
    EOT
  }
}
