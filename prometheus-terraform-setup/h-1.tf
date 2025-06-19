resource "helm_release" "demo_prometheus_stack" {
  name             = "demo-prometheus"
  namespace        = "demo-monitoring"
  create_namespace = true
  chart            = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  version          = "56.6.2"

  skip_crds = true

  # ── disable the chart’s own CRD hooks ──
  set {
    name  = "installCRDs"
    value = "false"
  }
  set {
    name  = "prometheusOperator.crdInstall"
    value = "false"
  }

  # ── skip shared RBAC & CR creations ──
  set {
    name  = "global.rbac.create"
    value = "false"
  }
  set {
    name  = "prometheusOperator.createCustomResource"
    value = "false"
  }

  # ── enable external access ──
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

  timeout = 600
}

Delay on Prometheus Automation – CRD Pre-Install Hook



Our Terraform + Helm pipeline is failing at the very first “pre-install” step.

The official kube-prometheus-stack chart includes a CRD install hook that must run before any of the workloads deploy.

Because this EKS cluster already hosts another Prometheus installation, those CRDs and cluster‐wide roles already exist and Helm’s hook either:

Times out waiting for resources it thinks it’s creating, or

Refuses to reuse them due to ownership conflicts.

Why it isn’t a simple re-run:

Helm tracks CRDs and ClusterRoles at the cluster scope (not namespace), so it can’t safely overwrite or skip them automatically.

We’ve tried all of the Terraform provider flags (skip_crds, disabling RBAC, custom resource flags, hook flags), but the chart’s CRD hook still runs and stal
