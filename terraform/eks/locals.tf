locals {
  name             = "aws-eks-demo"

  tags = {
    Region         = local.region
    CodeCommitRepo = local.name
    AWSOrg         = "Demo"
  }
}
