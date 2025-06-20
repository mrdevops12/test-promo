resource "helm_release" "demo_prometheus_stack" {
  name             = "demo-prometheus"
  namespace        = "demo-monitoring"
  create_namespace = true

  # make sure CRDs are already in place before Helm runs
  depends_on = [
    null_resource.install_prom_crds
  ]

  chart      = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  version    = "56.6.2"

  # skip CRD creation (we just installed them)
  skip_crds = true

  # avoid colliding with the existing Prometheus stack’s RBAC
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

  # give AWS LoadBalancers enough time
  timeout = 600
}
