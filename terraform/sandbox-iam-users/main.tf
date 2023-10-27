provider "aws" {
  region = local.region
  profile = "aws-eks-demo"
}

data "aws_caller_identity" "current" {}

locals {
  name       = "eks-demo-cross-account"
  account_id = data.aws_caller_identity.current.account_id
  region     = "us-east-1"

  project_users = {
    "user1" = "cmiller",
    "user2" = "irwebembera",
  }

  # TODO: Update with list of trusted role ARNs
  trusted_role_arns = [
    # Personal Sandbox account
    "arn:aws:iam::576720715620:user/cm-cli-admin",
    # Addition Sandbox account(s)
    # "arn:aws:iam::account_id:user/example",
  ]

  tags = {
    Region         = local.region
    Name           = local.name
    CodeCommitRepo = "aws-eks-demo"
    AWSOrg         = "Demo"
  }
}

######################
# IAM Users
# Must access AWS Console with IAM another IAM user
# to enable console access for these users
######################
module "iam_users" {
  source = "terraform-aws-modules/iam/aws//modules/iam-user"

  for_each = local.project_users

  name          = each.value
  force_destroy = true

  create_iam_user_login_profile = false
  password_reset_required       = false

  create_iam_access_key = false
}

# TODO - Delete this
# module "iam_assumable_eks_project_role" {
#   source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"


#   trusted_role_arns = local.trusted_role_arns

#   create_role = true

#   role_name         = "${local.name}-role"
#   role_requires_mfa = false

#   custom_role_policy_arns = [
#     module.iam_policy_allow_eks_cluster_access.arn,
#   ]

#   number_of_custom_role_policy_arns = 1
# }

data "aws_iam_policy_document" "eks_demo_permissions" {
  statement {
    effect = "Allow"

    actions = [
      "eks:DescribeCluster",
      "eks:ListClusters",
      "eks:ListFargateProfiles",
      "eks:ListNodegroups",
      "eks:ListNodegroups",
      "eks:ListUpdates",
      "eks:AccessKubernetesApi",
    ]
    resources = ["*"]
  }

  # Add statement to allow users to create their own access keys
  statement {
    sid = "AllowUserToCreateAccessKeys"
    effect = "Allow"

    actions = ["iam:*AccessKey*"]
    resources = ["arn:aws:iam::*:user/$${aws:username}"]
  }

  statement {
    sid = "ViewOwnUserInfo"
    effect = "Allow"

    actions = [
      "iam:GetUserPolicy",
      "iam:ListGroupsForUser",
      "iam:ListAttachedUserPolicies",
      "iam:ListUserPolicies",
      "iam:GetUser"
    ]
    resources = ["arn:aws:iam::*:user/$${aws:username}"]
  }

  statement {
    sid = "NavigateInConsole"
    effect = "Allow"

    actions = [
      "iam:GetGroupPolicy",
      "iam:GetPolicyVersion",
      "iam:GetPolicy",
      "iam:ListAttachedGroupPolicies",
      "iam:ListGroupPolicies",
      "iam:ListPolicyVersions",
      "iam:ListPolicies",
      "iam:ListUsers"
    ]
    resources = ["*"]
  }
}

module "iam_policy_allow_eks_cluster_access" {
  source = "terraform-aws-modules/iam/aws//modules/iam-policy"

  name        = "${local.name}-policy"
  path        = "/"
  description = "Policy to allow access to EKS cluster"

  policy = data.aws_iam_policy_document.eks_demo_permissions.json
}

module "iam_group_with_policies" {
  source = "terraform-aws-modules/iam/aws//modules/iam-group-with-policies"

  name = "${local.name}-group"

  group_users = [
    "cmiller",
    "irwebembera",
  ]

  # Attach IAM policy to allow users to manage their credentials and MFA
  # setting to false because a deny rule is added that overrides custom policy settings
  attach_iam_self_management_policy = false

  custom_group_policy_arns = [
    module.iam_policy_allow_eks_cluster_access.arn,
  ]
}
