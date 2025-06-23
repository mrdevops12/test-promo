provider "kubernetes" {
  # your kubeconfig, in-cluster, etc.
  config_path = "~/.kube/config"
}

resource "kubernetes_namespace" "demo_monitoring" {
  metadata {
    name = "demo-monitoring"
  }
}

resource "null_resource" "install_prometheus_via_template" {
  # re-run whenever chart_version or namespace changes
  triggers = {
    version   = var.chart_version
    namespace = kubernetes_namespace.demo_monitoring.metadata[0].name
  }

  # ensure namespace exists first
  depends_on = [ kubernetes_namespace.demo_monitoring ]

  provisioner "local-exec" {
    interpreter = ["bash","-c"]
    command     = <<-EOT
      set -e

      helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || true
      helm repo update

      helm template demo-prometheus prometheus-community/kube-prometheus-stack \
        --version ${self.triggers.version} \
        --namespace ${self.triggers.namespace} \
        --skip-crds \
        --set global.rbac.create=false \
        --set prometheusOperator.createCustomResource=false \
        --set prometheus.service.type=LoadBalancer \
        --set grafana.enabled=true \
        --set grafana.service.type=LoadBalancer \
      > /tmp/demo-prometheus.yaml

      kubectl apply -f /tmp/demo-prometheus.yaml

      kubectl rollout status statefulset/prometheus-kube-prometheus-stack-prometheus \
        -n ${self.triggers.namespace} --timeout=10m
      kubectl rollout status deployment/kube-prometheus-stack-grafana \
        -n ${self.triggers.namespace} --timeout=10m

      echo "✅ Prometheus + Grafana are up in ${self.triggers.namespace}!"
    EOT
  }
}
