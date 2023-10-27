######################
# ArgoCD
######################
resource "kubernetes_namespace" "argocd" {
  metadata {
    annotations = { name = "argocd" }
    labels      = { project = local.cluster_name }
    name        = "argocd"
  }

  provisioner "local-exec" {
    # Finalizers are not removed by the above command, so we need to use the following
    command = "./remove-k8s-finalizers.sh argocd namespace"
    when    = destroy
  }
}

resource "helm_release" "argo_cd" {
  name       = "argo"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  # version    = "6.0.1"

  values = [
    "${file("${local.values_file_dir}/argocd-values.yaml")}"
  ]

  depends_on = [kubernetes_namespace.argocd]
}

resource "kubernetes_service" "argocd" {
  metadata {
    name      = "argocd-service"
    namespace = kubernetes_namespace.argocd.metadata[0].name
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
  depends_on = [kubernetes_namespace.argocd]
}

resource "kubernetes_ingress_v1" "argocd_ingress" {
  metadata {
    name      = "ingress-argocd"
    namespace = kubernetes_namespace.argocd.metadata[0].name
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
  depends_on = [kubernetes_namespace.argocd]

  provisioner "local-exec" {
    command = "./remove-k8s-finalizers.sh argocd ingress"
    when    = destroy
  }
}
