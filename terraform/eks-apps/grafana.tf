######################
# Grafana LGTM Stack
######################
resource "kubernetes_namespace" "monitoring" {
  metadata {
    annotations = { name = "monitoring" }
    labels      = { project = local.cluster_name }
    name        = "monitoring"
  }

  provisioner "local-exec" {
    # Finalizers are not removed by the above command, so we need to use the following
    command = "./remove-k8s-finalizers.sh monitoring namespace"
    when    = destroy
  }
}

######################
# Helm Releases
######################
variable "helm_releases" {
  description = "A map of Helm release configurations"
  type = map(object({
    name        = string
    repository  = string
    chart       = string
    version     = optional(string)
    set_values  = optional(map(string))
    values_file = string
  }))
  default = {
    grafana-operator = {
      name        = "grafana-operator"
      repository  = "https://grafana.github.io/helm-charts"
      chart       = "grafana-agent-operator"
      values_file = "grafana-operator-values.yaml"
    },
    grafana-promtail = {
      name        = "grafana-promtail"
      repository  = "https://grafana.github.io/helm-charts"
      chart       = "promtail"
      values_file = "grafana-promtail-values.yaml"
    },
    grafana-loki = {
      name        = "grafana-loki-distributed"
      repository  = "https://grafana.github.io/helm-charts"
      chart       = "loki-distributed"
      values_file = "grafana-loki-distributed-values.yaml"
    },
    grafana-prometheus = {
      name        = "grafana-prometheus"
      repository  = "https://prometheus-community.github.io/helm-charts"
      chart       = "kube-prometheus-stack"
      values_file = "grafana-prometheus-community-values.yaml"
    },
    grafana-tempo = {
      name        = "grafana-tempo"
      repository  = "https://grafana.github.io/helm-charts"
      chart       = "tempo-distributed"
      values_file = "grafana-tempo-distributed-values.yaml"
    },
    grafana-mimir = {
      name        = "grafana-mimir"
      repository  = "https://grafana.github.io/helm-charts"
      chart       = "mimir-distributed"
      values_file = "grafana-mimir-distributed-values.yaml"
    },
  }
}

resource "helm_release" "releases" {
  for_each = var.helm_releases

  name       = each.value.name
  repository = each.value.repository
  chart      = each.value.chart
  version    = each.value.version != null ? each.value.version : null
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  values = [
    "${file("${local.values_file_dir}/${each.value.values_file}")}"
  ]

  dynamic "set" {
    for_each = each.value.set_values != null ? each.value.set_values : {}

    content {
      name  = set.key
      value = set.value
    }
  }

  depends_on = [kubernetes_namespace.monitoring]
}

######################
# Grafana Ingress
######################
resource "kubernetes_service" "grafana_service" {
  metadata {
    name      = "grafana-service"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    annotations = {
      "alb.ingress.kubernetes.io/healthcheck-path" = "/api/health"
    }
  }

  spec {
    selector = {
      "app.kubernetes.io/name" = "grafana"
    }

    session_affinity = "None"

    port {
      port        = 3000
      target_port = 3000
      protocol    = "TCP"
    }

    type = "NodePort"
  }

  depends_on = [kubernetes_namespace.monitoring]
}

resource "kubernetes_ingress_v1" "grafana_ingress" {
  metadata {
    name      = "ingress-grafana"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class"                = "alb"
      "alb.ingress.kubernetes.io/scheme"           = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"      = "ip"
      "alb.ingress.kubernetes.io/healthcheck-path" = "/api/health"
    }
  }

  spec {
    ingress_class_name = "alb"

    rule {
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "grafana-service"
              port {
                number = 3000
              }
            }
          }
        }
      }
    }
  }

  depends_on = [
    helm_release.aws_eks_alb,
    kubernetes_service.grafana_service,
    kubernetes_namespace.monitoring,
  ]

  provisioner "local-exec" {
    command = "./remove-k8s-finalizers.sh monitoring ingress"
    when    = destroy
  }
}
