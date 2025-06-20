resource "null_resource" "install_prom_crds" {
  # Any change to the CRD pack (or chart version) will re-run this
  triggers = {
    chart_version = "56.6.2"
  }

  provisioner "local-exec" {
    command = <<EOT
      set -e
      # download & unpack the chart
      helm pull prometheus-community/kube-prometheus-stack \
        --version ${self.triggers.chart_version} --untar --untardir ./crds_temp
      # apply just the CRDs
      kubectl apply -f ./crds_temp/kube-prometheus-stack/crds/
      rm -rf ./crds_temp
    EOT
    interpreter = ["bash", "-c"]
  }
}
