locals {
  name             = "aws-eks-demo"
  aws_eks_alb_name = "aws-load-balancer-controller"

  values_file_dir = "${path.module}/../../kubernetes/helm/eks/values"

  tags = {
    Region         = local.region
    CodeCommitRepo = local.name
    AWSOrg         = "Demo"
  }
}
