/*
The cleanup lambda function

This function will clean up the active EKS sandbox cluster
and any associated RDS instances to save on costs.
*/

provider "aws" {
  region = local.region
  profile = "aws-eks-demo"
}

data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}
data "aws_region" "current" {}

locals {
  name        = "aws-eks-demo"
  lambda_name = "${local.name}-cleanup-lambda"
  account_id  = data.aws_caller_identity.current.account_id
  region      = "us-east-1"

  tags = {
    Region         = local.region
    CodeCommitRepo = local.name
    AWSOrg         = "Demo"
  }
}

#############################
# IAM Policy for Lambda
#############################
data "aws_iam_policy_document" "lambda_policy" {
  statement {
    effect = "Allow"
    actions = [
      "eks:ListClusters",
      "eks:ListNode*",
      "eks:DeleteCluster",
      "eks:DeleteNodegroup",
      "rds:ListDBClusters",
      "rds:DescribeDBInstances",
      "sns:Publish"
    ]
    resources = ["*"]
  }
}

module "iam_policy_eks_lambda" {
  source      = "terraform-aws-modules/iam/aws//modules/iam-policy"
  name        = "${local.name}-policy"
  path        = "/"
  description = "Policy to allow lambda function to list EKS clusters"
  policy      = data.aws_iam_policy_document.lambda_policy.json
}

#############################
# Lambda Function
#############################
resource "aws_lambda_alias" "main" {
  name             = "${local.lambda_name}-alias"
  description      = "EKS Demo Cleanup Lambda"
  function_name    = module.lambda_function.lambda_function_arn
  function_version = "$LATEST"
}

module "lambda_function" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = local.lambda_name
  description   = "Lambda function to automatically cleanup EKS resources each night"
  handler       = "index.lambda_handler"
  runtime       = "python3.10"
  timeout       = 60 # seconds

  source_path = "./src/cleanup-eks"

  environment_variables = {
    # EKS_CLUSTER_PREFIX = local.name
    EKS_CLUSTER_PREFIX = "aws-eks-demo-default"
    SNS_TOPIC_ARN      = aws_sns_topic.eks_cleanup.arn
  }

  attach_policy = true
  policy        = module.iam_policy_eks_lambda.arn

  tags = merge(
    local.tags,
    {
      Name = local.lambda_name
    }
  )
}
