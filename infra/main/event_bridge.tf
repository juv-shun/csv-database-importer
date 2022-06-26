#####################################
# EventBridge
#####################################
resource "aws_cloudwatch_event_rule" "artifact_event" {
  name = "${var.service_name}-s3-event"

  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail-type = ["Object Created"]
    detail = {
      bucket = {
        name = [var.s3_bucket]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "artifact_event" {
  target_id = "TriggerStepFunctions"
  rule      = aws_cloudwatch_event_rule.artifact_event.name
  arn       = aws_sfn_state_machine.state_machine.arn
  role_arn  = aws_iam_role.events_role.arn
}

#####################################
# IAM
#####################################
resource "aws_iam_role" "events_role" {
  name               = "${var.service_name}-events-role"
  assume_role_policy = data.aws_iam_policy_document.events_assume_policy.json
}

resource "aws_iam_role_policy" "events_policy" {
  name = "ECSTaskRunPolicy"
  role = aws_iam_role.events_role.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "states:StartExecution"
        Effect   = "Allow"
        Resource = aws_sfn_state_machine.state_machine.arn
      },
    ]
  })
}

data "aws_iam_policy_document" "events_assume_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}
