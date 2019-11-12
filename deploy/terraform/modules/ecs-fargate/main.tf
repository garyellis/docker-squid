data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "ecs_assume_role" {
  statement {
    actions       = ["sts:AssumeRole"]
    effect        = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ecs_task" {
  statement {
    sid     = "ECSECRAccess"
    effect  = "Allow"
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetAuthorizationToken",
    ]
    resources = ["*"]
  }

  statement {
    sid     = "ECSSSMRead"
    effect  = "Allow"
    actions = [
      "ssm:GetParameters",
      "secretsmanager:GetSecretValue",
      "kms:Decrypt",
    ]
    resources = [
      "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter${var.squid_whitelist_ssm_parameter_name}",
      "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter${var.squid_conf_ssm_parameter_name}",
    ]
  }
}

data "aws_iam_policy_document" "ecs_task_kms" {
  count = var.ssm_kms_key_arn != "" ? 1 : 0

  statement {
    sid     = "ECSKMSDecrypt"
    effect  = "Allow"
    actions = [
      "kms:Decrypt"
    ]
    resources = [
      var.ssm_kms_key_arn
    ]
  }
}


resource "aws_iam_policy" "ecs_task" {
  name_prefix = format("%s-codebuild", var.name)
  policy      = element(
    compact(
      concat(
        data.aws_iam_policy_document.ecs_task.*.json,
        data.aws_iam_policy_document.ecs_task_kms.*.json
      ),
    ),
    0,
  )
}

resource "aws_iam_role" "ecs_task" {
  name_prefix        = format("%s-ecs-task-role", var.name)
  description        = "ecs task execution role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json
  tags               = merge(map("Name", format("%s-ecs-task-execution-role", var.name)), var.tags) 
}

locals {
  ecs_task_iam_policy_arns = compact(concat(var.ecs_task_iam_policy_attachment_arns, aws_iam_policy.ecs_task.*.arn))
}

resource "aws_iam_role_policy_attachment" "ecs_task_policy_attachments" {
  count = var.ecs_task_iam_policy_attachment_arns_count + 1

  role       = aws_iam_role.ecs_task.name
  policy_arn = local.ecs_task_iam_policy_arns[count.index]
}

resource "aws_ssm_parameter" "squid_witelist" {
  name  = var.squid_whitelist_ssm_parameter_name
  type  = "String"
  value = " "
}


resource "aws_ssm_parameter" "squid_conf" {
  name  = var.squid_conf_ssm_parameter_name
  type  = "String"
  value = " "
}



#### ecs configuration
resource "aws_ecs_task_definition" "squid" {
  name    = var.name
}

data "aws_ecs_task_definition" "squid" {
  task_definition = var.name

  depends_on = [aws_ecs_task_definition.squid]
}

resource "aws_ecs_service" "squid" {
  name            = var.name
  cluster         = ""
  task_definition = ""
  desired_count   = var.ecs_service_desired_count
  launch_type     = "FARGATE"
  

  network_configuration {
    subnets          = var.subnets
    security_groups  = 
    assign_public_ip = var.assign_public_ip
  }

}
