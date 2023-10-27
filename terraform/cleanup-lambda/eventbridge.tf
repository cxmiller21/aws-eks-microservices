/*
The EventBridge scheduler for the cleanup lambda function

This will run at 4:30pm CST every day to clean up the EKS resources
*/

#####################################################
# IAM Roles and Permissions for EventBridge Scheduler
#####################################################
data "aws_iam_policy_document" "scheduler_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account_id]
    }
  }
}

resource "aws_iam_role" "scheduler" {
  name               = "${local.lambda_name}-scheduler-role"
  assume_role_policy = data.aws_iam_policy_document.scheduler_role.json
  tags               = local.tags
}

data "aws_iam_policy_document" "schduler_policy" {
  statement {
    effect = "Allow"

    actions = [
      "lambda:InvokeFunction",
    ]

    resources = [
      "arn:aws:lambda:${local.region}:${local.account_id}:function:${local.lambda_name}",
      "arn:aws:lambda:${local.region}:${local.account_id}:function:${local.lambda_name}:*"
    ]
  }
}

resource "aws_iam_policy" "scheduler" {
  name        = "${local.lambda_name}-eventbridge-schdeuler-policy"
  path        = "/"
  description = "IAM policy for invoking a lambda function from an EventBridge schedule"
  policy      = data.aws_iam_policy_document.schduler_policy.json
}

resource "aws_iam_role_policy_attachment" "scheduler" {
  role       = aws_iam_role.scheduler.name
  policy_arn = aws_iam_policy.scheduler.arn
}

#####################################################
# EventBridge Scheduler Resources
#####################################################
resource "aws_scheduler_schedule_group" "lambda" {
  name = "${local.name}-group"
  tags = local.tags
}

resource "aws_scheduler_schedule" "cron" {
  name       = "${local.name}-schedule"
  group_name = aws_scheduler_schedule_group.lambda.name

  flexible_time_window {
    maximum_window_in_minutes = 15
    mode                      = "FLEXIBLE"
  }

  # Run at 4:30pm CST every day
  schedule_expression          = "cron(30 16 * * ? *)"
  schedule_expression_timezone = "America/Chicago"
  state                        = "ENABLED" # "DISABLED"

  target {
    arn      = aws_lambda_alias.main.arn
    role_arn = aws_iam_role.scheduler.arn

    retry_policy {
      maximum_event_age_in_seconds = 60
      maximum_retry_attempts       = 3
    }
  }

  depends_on = [
    aws_iam_role.scheduler,
  ]
}
