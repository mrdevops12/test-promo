resource "helm_release" "demo_prometheus_stack" {
  name             = "demo-prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = "56.6.2"
  namespace        = "demo-monitoring"
  create_namespace = true

  skip_crds = true  # 🔐 Avoid conflict with CRDs

  set {
    name  = "global.rbac.create"
    value = "false"  # 🔐 Avoid conflict with ClusterRole
  }

  set {
    name  = "prometheusOperator.createCustomResource"
    value = "false"  # 🔐 Avoid CRD-related custom resources
  }

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

  set {
    name  = "prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues"
    value = "false"
  }
}
