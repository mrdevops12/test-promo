resource "helm_release" "demo_prometheus_stack" {
  name             = "demo-prometheus"
  namespace        = "demo-monitoring"
  create_namespace = true
  chart            = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  version          = "56.6.2"

  skip_crds = true  # ✅ Prevent CRD conflict

  # ✅ Prevent cluster-wide RBAC & CR creation conflict
  set {
    name  = "global.rbac.create"
    value = "false"
  }

  set {
    name  = "prometheusOperator.createCustomResource"
    value = "false"
  }

  # ✅ Enable access for Prometheus and Grafana
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

  # Optional: Prometheus config
  set {
    name  = "prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues"
    value = "false"
  }

  # Optional: extend install time
  timeout = 600
}
