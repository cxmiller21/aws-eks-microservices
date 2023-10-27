################################################################################
# Grafana and ArgoCD
# Outputs will fail initially because the load
# balancer hostnames are not ready yet
################################################################################
/*
output "grafana_load_balancer_hostname" {
  value = kubernetes_ingress_v1.grafana_ingress.status.0.load_balancer.0.ingress.0.hostname
  # value = length(
  #   kubernetes_ingress_v1.grafana_ingress.status.0.load_balancer.0.ingress.0.hostname
  # ) > 0 ? kubernetes_ingress_v1.grafana_ingress.status.0.load_balancer.0.ingress.0.hostname : "not ready yet"
  depends_on = [kubernetes_ingress_v1.grafana_ingress]
}

output "argocd_load_balancer_hostname" {
  value = kubernetes_ingress_v1.argocd_ingress.status.0.load_balancer.0.ingress.0.hostname
  # value = length(
  #   kubernetes_ingress_v1.argocd_ingress.status.0.load_balancer.0.ingress.0.hostname
  # ) > 0 ? kubernetes_ingress_v1.argocd_ingress.status.0.load_balancer.0.ingress.0.hostname : "not ready yet"
  depends_on = [kubernetes_ingress_v1.argocd_ingress]
}
*/
