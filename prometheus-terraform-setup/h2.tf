resource "helm_release" "demo_prometheus_stack" {
  name             = "demo-prometheus"
  namespace        = "demo-monitoring"
  create_namespace = true

  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "69.3.0"

  # 1) Never render or install any CRDs
  skip_crds     = true
  # 2) Never run any hooks (CRDs or otherwise)
  disable_hooks = true

  # 3) Disable the chart’s cluster-wide RBAC pieces
  set {
    name  = "global.rbac.create"
    value = "false"
  }
  set {
    name  = "prometheusOperator.createCustomResource"
    value = "false"
  }

  # 4) Expose services externally
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

  # 5) Give AWS time to provision ELBs
  timeout = 600
  # (optional) Roll back on failure
  atomic  = true
}







