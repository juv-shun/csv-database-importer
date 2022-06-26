#####################################
# ECR
#####################################
resource "aws_ecr_repository" "ecr" {
  name = var.service_name
}

resource "aws_ecr_lifecycle_policy" "ecr_lifecycle" {
  repository = aws_ecr_repository.ecr.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Delete old images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

#####################################
# ECS
#####################################
resource "aws_ecs_cluster" "cluster" {
  name = var.service_name
}

resource "aws_ecs_task_definition" "task_def" {
  family                   = var.service_name
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  network_mode             = "awsvpc"
  task_role_arn            = aws_iam_role.task_role.arn
  execution_role_arn       = aws_iam_role.task_exe_role.arn
  container_definitions = jsonencode(
    [
      {
        name      = "app"
        image     = "${aws_ecr_repository.ecr.repository_url}:latest"
        essential = true
        environment = [
          {
            name  = "DB_HOST"
            value = var.task_def_environments.db_host
          },
          {
            name  = "DB_USER"
            value = var.task_def_environments.db_user
          },
          {
            name  = "DB_NAME"
            value = var.task_def_environments.db_name
          }
        ]
        secrets = [
          {
            name      = "DB_PASSWORD"
            valueFrom = "/${var.service_name}/DB_PASSWORD"
          },
        ]
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-group         = "/aws/ecs/${var.service_name}"
            awslogs-region        = "ap-northeast-1"
            awslogs-stream-prefix = "app"
          }
        }
      }
    ]
  )
}

#####################################
# IAM
#####################################
resource "aws_iam_role" "task_exe_role" {
  name               = "${var.service_name}-task-exe-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_policy.json
}

resource "aws_iam_role_policy" "task_exe_role_policy" {
  name = "GetParamPolicy"
  role = aws_iam_role.task_exe_role.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "ssm:GetParameters"
        Effect   = "Allow"
        Resource = "arn:aws:ssm:ap-northeast-1:${data.aws_caller_identity.aws_identity.account_id}:parameter/${var.service_name}/*"
      }
    ]
  })
}

resource "aws_iam_role" "task_role" {
  name               = "${var.service_name}-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_policy.json
}

resource "aws_iam_role_policy" "task_role_policy" {
  name = "S3GetPolicy"
  role = aws_iam_role.task_role.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:GetObjectAcl"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::${var.s3_bucket}",
          "arn:aws:s3:::${var.s3_bucket}/*"
        ]
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "task_exe_role_attachment" {
  role       = aws_iam_role.task_exe_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "ecs_assume_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

#####################################
# CloudWatch Logs
#####################################
resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/aws/ecs/${var.service_name}"
  retention_in_days = 7
}
