resource "null_resource" "install_prom_crds" {
  # whenever you bump chart version here, re‐run CRD install
  triggers = {
    chart_version = "56.6.2"
  }

  provisioner "local-exec" {
    command = <<EOT
      set -e
      helm pull prometheus-community/kube-prometheus-stack \
        --version ${self.triggers.chart_version} --untar --untardir ./crd_tmp
      kubectl apply -f crd_tmp/kube-prometheus-stack/crds/
      rm -rf crd_tmp
    EOT
    interpreter = ["bash", "-c"]
  }
}
