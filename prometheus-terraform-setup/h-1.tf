resource "helm_release" "demo_prometheus_stack" {
  name             = "demo-prometheus"
  namespace        = "demo-monitoring"
  create_namespace = true
  version          = "56.6.2"
  chart            = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"

  # ensure CRDs are applied first
  depends_on = [
    null_resource.install_prom_crds
  ]

  # skip any CRDs in the chart itself
  skip_crds = true

  # disable chart’s cluster-role & CR creation
  set {
    name  = "global.rbac.create"
    value = "false"
  }
  set {
    name  = "prometheusOperator.createCustomResource"
    value = "false"
  }

  # expose Prometheus & Grafana
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

  # allow ELBs time to come up
  timeout = 600
}
