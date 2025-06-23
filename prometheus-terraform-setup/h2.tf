resource "helm_release" "demo_prometheus_stack" {
  depends_on      = [ null_resource.vendor_prom_chart ]
  name             = "demo-prometheus"
  namespace        = "demo-monitoring"
  create_namespace = true

  # Use your vendored + patched chart
  chart   = "${path.module}/charts/kube-prometheus-stack"
  version = "69.3.0"

  # harmless now, since no CRDs remain
  skip_crds = true

  # disable all cluster-wide RBAC (no ClusterRoles/Bindings)
  set {
    name  = "global.rbac.create"
    value = "false"
  }
  set {
    name  = "prometheusOperator.createCustomResource"
    value = "false"
  }

  # expose Prometheus & Grafana via LoadBalancer
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
