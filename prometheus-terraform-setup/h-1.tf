resource "helm_release" "demo_prometheus_stack" {
  depends_on      = [null_resource.vendor_prom_chart]
  name             = "demo-prometheus"
  namespace        = "demo-monitoring"
  create_namespace = true

  # point at your local copy of the chart
  chart            = "${path.module}/chart_dir/kube-prometheus-stack"
  # you can omit repository when using local chart
  version          = "56.6.2"

  # tell Terraform’s Helm provider not to render any CRDs
  skip_crds        = true

  # avoid re-creating any cluster-wide RBAC
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

  # give AWS time to provision LBs
  timeout = 600
}
