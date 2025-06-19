resource "helm_release" "demo_prometheus_stack" {
  name             = "demo-prometheus"
  namespace        = "demo-monitoring"
  create_namespace = true

  chart       = "kube-prometheus-stack"
  repository  = "https://prometheus-community.github.io/helm-charts"
  version     = "56.6.2"

  # <-- skip all CRDs at the Terraform level -->
  skip_crds = true

  # <-- disable the chart’s internal CRD hooks -->
  set { name = "installCRDs"                    value = "false" }
  set { name = "crds.enabled"                   value = "false" }
  set { name = "prometheusOperator.crdInstall"  value = "false" }

  # <-- disable recreating any cluster-wide RBAC -->
  set { name = "global.rbac.create"                 value = "false" }
  set { name = "prometheusOperator.createCustomResource" value = "false" }

  # <-- your usual UI & LB settings -->
  set { name = "prometheus.service.type"          value = "LoadBalancer" }
  set { name = "grafana.enabled"                 value = "true" }
  set { name = "grafana.service.type"            value = "LoadBalancer" }

  timeout = 600  # allow 10 min for AWS ELB provisioning
}
