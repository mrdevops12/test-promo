resource "helm_release" "demo_prometheus_stack" {
  depends_on      = [ null_resource.vendor_prom_chart ]
  name             = "demo-prometheus"
  namespace        = "demo-monitoring"
  create_namespace = true

  # Install from your local, patched chart
  chart   = "${path.module}/charts/kube-prometheus-stack"
  version = "69.3.0"

  # skip_crds is now harmless (no CRDs remain)
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

  # expose Prometheus & Grafana externally
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

  # give AWS time to provision ELBs
  timeout = 600
}
