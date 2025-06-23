resource "helm_release" "demo_prometheus_stack" {
  depends_on      = [ null_resource.vendor_prom_chart ]
  name             = "demo-prometheus"
  namespace        = "demo-monitoring"
  create_namespace = true

  # Install from your locally patched copy
  chart   = "${path.module}/charts/kube-prometheus-stack"
  version = "69.3.0"

  # no CRDs here
  skip_crds = true

  # disable cluster-wide RBAC/CR creation
  set {
    name  = "global.rbac.create"
    value = "false"
  }
  set {
    name  = "prometheusOperator.createCustomResource"
    value = "false"
  }

  # expose UIs externally
  set {
    name  = "prometheus.service.type"
    value = "LoadBalancer"
  }
  set {
    name  = "grafana.enabled"
    value = "true"
  }
  set {
    name  = "grafana.service.type"
    value = "LoadBalancer"
  }

  timeout = 600
}
