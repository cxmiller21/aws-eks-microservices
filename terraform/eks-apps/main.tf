provider "aws" {
  region  = local.region
  profile = "aws-eks-demo"
}

data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}
data "aws_region" "current" {}

locals {
  account_id       = data.aws_caller_identity.current.account_id
  region           = "us-east-1"
  cluster_name     = "aws-eks-demo"
  project_prefix   = "${local.cluster_name}-${terraform.workspace}"
  aws_eks_alb_name = "aws-load-balancer-controller"

  ssm_parameter_prefix = replace(replace(local.project_prefix, "aws-", ""), "-", "_") # replace(local.project_prefix, "aws-", "")

  values_file_dir = "${path.module}/../../kubernetes/helm/eks/values"

  tags = {
    Region         = local.region
    CodeCommitRepo = local.cluster_name
    AWSOrg         = "Demo"
  }
}

# Kubernetes Resources
data "aws_ssm_parameter" "eks_cluster_certificate_authority_data" {
  name = "/${local.ssm_parameter_prefix}/cluster_certificate_authority_data"
}

data "aws_ssm_parameter" "eks_cluster_endpoint" {
  name = "/${local.ssm_parameter_prefix}/cluster_endpoint"
}

provider "kubernetes" {
  host                   = data.aws_ssm_parameter.eks_cluster_endpoint.value
  cluster_ca_certificate = base64decode(data.aws_ssm_parameter.eks_cluster_certificate_authority_data.value)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", local.cluster_name]
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
    host                   = data.aws_ssm_parameter.eks_cluster_endpoint.value
    cluster_ca_certificate = base64decode(data.aws_ssm_parameter.eks_cluster_certificate_authority_data.value)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", local.cluster_name]
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
    value = local.cluster_name
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
