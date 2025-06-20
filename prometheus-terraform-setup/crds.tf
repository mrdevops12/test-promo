resource "null_resource" "install_prom_crds" {
  triggers = {
    chart_version = "56.6.2"
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOT
      set -e

      # 1) Ensure the Prometheus Community repo is added
      if ! helm repo list | grep -q '^prometheus-community'; then
        helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
      fi
      helm repo update

      # 2) Pull & unpack the exact chart version
      helm pull prometheus-community/kube-prometheus-stack \
        --version ${self.triggers.chart_version} \
        --untar --untardir ./crd_tmp

      # 3) Apply its CRDs
      kubectl apply -f ./crd_tmp/kube-prometheus-stack/crds/

      # 4) Clean up
      rm -rf ./crd_tmp
    EOT
  }
}
