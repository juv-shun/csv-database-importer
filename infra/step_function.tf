#####################################
# Step Function
#####################################
resource "aws_sfn_state_machine" "state_machine" {
  name     = var.service_name
  role_arn = aws_iam_role.state_machine.arn

  definition = jsonencode({
    Comment = "Run an ECS task"
    StartAt = "GenerateCommands"
    States = {
      GenerateCommands = {
        Type = "Pass"
        Next = "RunTask"
        Parameters = {
          "commands.$" = "States.Array('python', 'app/main.py', '--bucket', $$.Execution.Input.detail.bucket.name, '--object', $$.Execution.Input.detail.object.key)"
        }
      }
      RunTask = {
        Type     = "Task"
        Resource = "arn:aws:states:::ecs:runTask.sync"
        Parameters = {
          LaunchType     = "FARGATE"
          Cluster        = aws_ecs_cluster.cluster.arn
          TaskDefinition = aws_ecs_task_definition.task_def.arn
          NetworkConfiguration = {
            AwsvpcConfiguration = {
              Subnets = [
                aws_subnet.public_subnet_az1.id,
                aws_subnet.public_subnet_az2.id,
              ]
              SecurityGroups = [aws_default_security_group.default.id]
              AssignPublicIp = "ENABLED"
            }
          }
          Overrides = {
            ContainerOverrides = [
              {
                Name        = "app"
                "Command.$" = "$.commands"
              }
            ]
          }
        }
        End = true
      }
    }
  })

  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.state_machine_log_group.arn}:*"
    include_execution_data = true
    level                  = "ERROR"
  }

  depends_on = [
    aws_ecs_cluster.cluster,
    aws_ecs_task_definition.task_def
  ]
}


#####################################
# IAM
#####################################
resource "aws_iam_role" "state_machine" {
  name               = "${var.service_name}-step-function-role"
  assume_role_policy = data.aws_iam_policy_document.state_machine_assume_policy.json
}

resource "aws_iam_role_policy" "ecs_run_policy" {
  name = "ECSTaskRunPolicy"
  role = aws_iam_role.state_machine.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "ecs:RunTask"
        Effect   = "Allow"
        Resource = "arn:aws:ecs:ap-northeast-1:100994446770:task-definition/s3-event-trigger-fargate:*"
      },
      {
        Action = [
          "ecs:StopTask",
          "ecs:DescribeTasks",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "events:PutTargets",
          "events:PutRule",
          "events:DescribeRule",
        ]
        Effect   = "Allow"
        Resource = "arn:aws:events:ap-northeast-1:100994446770:rule/StepFunctionsGetEventsForECSTaskRule"
      },
      {
        Action = [
          "iam:GetRole",
          "iam:PassRole",
        ]
        Effect = "Allow"
        Resource = [
          aws_iam_role.task_exe_role.arn,
          aws_iam_role.task_role.arn,
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "get_events_policy" {
  name = "XRayAccessPolicy"
  role = aws_iam_role.state_machine.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords",
          "xray:GetSamplingRules",
          "xray:GetSamplingTargets"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "logging_policy" {
  name = "LoggingPolicy"
  role = aws_iam_role.state_machine.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogDelivery",
          "logs:GetLogDelivery",
          "logs:UpdateLogDelivery",
          "logs:DeleteLogDelivery",
          "logs:ListLogDeliveries",
          "logs:PutResourcePolicy",
          "logs:DescribeResourcePolicies",
          "logs:DescribeLogGroups"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

data "aws_iam_policy_document" "state_machine_assume_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }
  }
}

#####################################
# CloudWatch Logs
#####################################
resource "aws_cloudwatch_log_group" "state_machine_log_group" {
  name              = "/aws/state/${var.service_name}"
  retention_in_days = 7
}
