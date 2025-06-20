 resource "helm_release" "demo_prometheus_stack" {
   name             = "demo-prometheus"
   namespace        = "demo-monitoring"
   create_namespace = true
   chart            = "kube-prometheus-stack"
   repository       = "https://prometheus-community.github.io/helm-charts"
   version          = "56.6.2"

   skip_crds = true

+  depends_on = [
+    null_resource.install_prom_crds
+  ]

   set {
     name  = "global.rbac.create"
     value = "false"
   }
   set {
     name  = "prometheusOperator.createCustomResource"
     value = "false"
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

   timeout = 600
 }
