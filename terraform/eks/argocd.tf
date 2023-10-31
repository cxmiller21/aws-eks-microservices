######################
# ArgoCD
######################
resource "helm_release" "argo_cd" {
  name       = "argo"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace.main["argocd"].metadata[0].name
  version    = "5.49.0"

  values = [
    "${file("${local.values_file_dir}/argocd-values.yaml")}"
  ]

  depends_on = [
    kubernetes_namespace.main["argocd"],
  ]
}

resource "helm_release" "argo_cd_applications" {
  name       = "argo-apps"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  namespace  = kubernetes_namespace.main["argocd"].metadata[0].name
  version    = "1.4.1"

  values = [
    "${file("${local.values_file_dir}/argocd-apps-values.yaml")}"
  ]

  depends_on = [
    kubernetes_namespace.main["argocd"],
    kubernetes_namespace.main["online_boutique"],
    helm_release.argo_cd,
  ]
}

resource "kubernetes_service" "argocd" {
  metadata {
    name      = "argocd-service"
    namespace = kubernetes_namespace.main["argocd"].metadata[0].name
    annotations = {
      "alb.ingress.kubernetes.io/healthcheck-path" = "/healthz"
    }
  }

  spec {
    selector = {
      "app.kubernetes.io/name" = "argocd-server"
    }

    session_affinity = "None"

    port {
      port        = 80
      target_port = 8080
      protocol    = "TCP"
    }

    type = "NodePort"
  }

  depends_on = [
    kubernetes_namespace.main["argocd"],
    helm_release.argo_cd,
  ]
}

resource "kubernetes_ingress_v1" "argocd_ingress" {
  metadata {
    name      = "ingress-argocd"
    namespace = kubernetes_namespace.main["argocd"].metadata[0].name
    annotations = {
      "alb.ingress.kubernetes.io/backend-protocol" = "HTTP"
      # "alb.ingress.kubernetes.io/listen-ports"     = "[{'HTTPS':443}]"
      "kubernetes.io/ingress.class"                = "alb"
      "alb.ingress.kubernetes.io/scheme"           = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"      = "ip"
      "alb.ingress.kubernetes.io/healthcheck-path" = "/healthz"
    }
  }

  spec {
    ingress_class_name = "alb"
    rule {
      http {
        path {
          path = "/*"
          backend {
            service {
              name = kubernetes_service.argocd.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_namespace.main["argocd"],
    helm_release.argo_cd,
  ]

  provisioner "local-exec" {
    command = "./remove-k8s-finalizers.sh argocd ingress"
    when    = destroy
  }
}
