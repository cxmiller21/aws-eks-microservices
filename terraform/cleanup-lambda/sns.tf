/*
The SNS resources to be alerted when the cleanup lambda function runs

This will send an email to the specified email address when the function completes
*/

locals {
  sns_subscription_emails = [
    "first.last@example.com"
  ]
}

resource "aws_sns_topic" "eks_cleanup" {
  name              = "${local.name}-topic"
  kms_master_key_id = "alias/aws/sns"
  tags              = local.tags
}

resource "aws_sns_topic_subscription" "eks_cleanup" {
  topic_arn = aws_sns_topic.eks_cleanup.arn
  protocol  = "email"
  endpoint  = join(",", local.sns_subscription_emails)
}

resource "aws_sns_topic_policy" "topic" {
  arn    = aws_sns_topic.eks_cleanup.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

data "aws_iam_policy_document" "sns_topic_policy" {
  policy_id = "__default_policy_ID"
  version   = "2008-10-17"

  statement {
    actions = [
      "SNS:Publish",
    ]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [module.lambda_function.lambda_function_arn]
    }

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = [
      aws_sns_topic.eks_cleanup.arn,
    ]

    sid = "allow_lambda_to_publish_to_sns"
  }

  statement {
    actions = [
      "SNS:GetTopicAttributes",
      "SNS:SetTopicAttributes",
      "SNS:AddPermission",
      "SNS:RemovePermission",
      "SNS:DeleteTopic",
      "SNS:Subscribe",
      "SNS:ListSubscriptionsByTopic",
      "SNS:Publish",
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"

      values = [
        local.account_id,
      ]
    }

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = [
      aws_sns_topic.eks_cleanup.arn,
    ]

    sid = "allow_owner_to_manage_sns_topic"
  }
}
