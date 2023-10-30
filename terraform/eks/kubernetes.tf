locals {
  aws_eks_alb_name = "aws-load-balancer-controller"
  values_file_dir = "${path.module}/../../kubernetes/helm/eks/values"

  kubernetes_namespaces = ["argocd", "online-boutique", "monitoring"]
  # kubernetes_namespaces = ["argocd", "online-boutique", "monitoring"]
}

/*
Needed to "fully" create the EKS cluster and the manage_aws_auth_configmap
https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html#aws-auth-configmap

"It is initially created to allow nodes to join your cluster, but you also use this
ConfigMap to add role-based access control (RBAC) access to IAM principals"
*/
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", local.name]
  }
}

resource "kubernetes_service_account" "aws_alb_controller" {
  metadata {
    name      = local.aws_eks_alb_name
    namespace = "kube-system"

    annotations = {
      "eks.amazonaws.com/role-arn" = "arn:aws:iam::${local.account_id}:role/${local.project_prefix}-eks-elb-role"
    }
    labels = {
      "app.kubernetes.io/component" = "controller"
      "app.kubernetes.io/name"      = local.aws_eks_alb_name
    }
  }
}

# Helm Resources
# Not creating AWS ALB for some reason (probably IAM permissions - need to debug further)
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", local.name]
    }
  }
}

resource "helm_release" "aws_eks_alb" {
  name       = local.aws_eks_alb_name
  repository = "https://aws.github.io/eks-charts"
  chart      = local.aws_eks_alb_name
  namespace  = "kube-system"
  # version    = "6.0.1"

  set {
    name  = "region"
    value = local.region
  }

  set {
    name  = "clusterName"
    value = local.name
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = local.aws_eks_alb_name
  }
}

############################
# Kubernetes Namespaces
############################
resource "kubernetes_namespace" "main" {
  for_each = toset(local.kubernetes_namespaces)
  metadata {
    annotations = { name = each.key }
    labels      = { project = local.name }
    name        = each.key
  }

  provisioner "local-exec" {
    # Finalizers are not removed by the above command, so we need to use the following
    command = "./remove-k8s-finalizers.sh ${each.key} namespace"
    when    = destroy
  }
}
