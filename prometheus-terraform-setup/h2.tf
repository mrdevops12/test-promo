resource "helm_release" "demo_prometheus_stack" {
  name             = "demo-prometheus"
  namespace        = "demo-monitoring"
  create_namespace = true

  # wait until we’ve vendored the chart
  depends_on = [ null_resource.vendor_prom_chart ]

  # point to the local copy, not the remote repo
  chart   = "${path.module}/charts/kube-prometheus-stack"
  version = "56.6.2"

  # no CRDs (we removed them)
  skip_crds = true

  # disable any cluster-wide RBAC/CR creation
  set {
    name  = "global.rbac.create"
    value = "false"
  }
  set {
    name  = "prometheusOperator.createCustomResource"
    value = "false"
  }

  # expose the UIs externally
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

  # give ELBs enough time
  timeout = 600
}
