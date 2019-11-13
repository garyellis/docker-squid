data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

#### ecs iam execution and task role configuration
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
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
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


#### cloud mapper configuration
locals {
  service_discovery_private_dns_namespace_id = var.service_discovery_private_dns_namespace_id == "" ? join("", aws_service_discovery_private_dns_namespace.squid.*.id) : var.service_discovery_private_dns_namespace_id
}

resource "aws_service_discovery_private_dns_namespace" "squid" {
  count = var.create_service_discovery_dns_namespace ? 1 : 0

  name        = var.service_discovery_private_dns_namespace_name
  description = var.service_discovery_private_dns_namespace_description
  vpc         = var.service_discovery_private_dns_namespace_vpc_id
}

resource "aws_service_discovery_service" "squid" {
  name = var.name
  dns_config {
    namespace_id = local.service_discovery_private_dns_namespace_id
    dns_records {
      ttl  = 60
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }
}


#### ecs task definition and service configuration
module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "v2.0.0"

  create_ecs = var.create_ecs_cluster
  name       = var.ecs_cluster_name
  tags       = var.tags
}

locals {
  container_definition = {
    name                    = var.name
    image                   = var.container_def_image
    essential               = true
    privileged              = false
    portMappings            = [{ containerPort = 3128 }]
    stopTimeout             = 60
    logConfiguration        = {
      logDriver = "awslogs"
      options   = {
        "awslogs-region"        = data.aws_region.current.name
        "awslogs-group"         = "ecs/${var.name}"
        "awslogs-stream-prefix" = var.name
      }
    }
    environment                 = var.container_def_environment
  }
  container_definition_json_map = jsonencode(local.container_definition)
  container_definition_json     = "[${local.container_definition_json_map}]"
}

resource "aws_ecs_task_definition" "squid" {
  family                   = var.name
  execution_role_arn       = aws_iam_role.ecs_task.arn
  task_role_arn            = aws_iam_role.ecs_task.arn
  network_mode             = "awsvpc"
  cpu                      = 2048
  memory                   = 4096
  
  container_definitions    = local.container_definition_json
  requires_compatibilities = ["FARGATE"]
}

data "aws_ecs_task_definition" "squid" {
  task_definition = var.name
  depends_on = [aws_ecs_task_definition.squid]
}

resource "aws_ecs_service" "squid" {
  name            = var.name
  cluster         = module.ecs.this_ecs_cluster_id
  task_definition = format("%s:%s",
    aws_ecs_task_definition.squid.family,
    max(aws_ecs_task_definition.squid.revision, data.aws_ecs_task_definition.squid.revision)
  )

  desired_count   = var.ecs_service_desired_count
  launch_type     = "FARGATE"
  
  network_configuration {
    subnets          = var.ecs_service_subnets
    security_groups  = var.ecs_service_security_group_attachments
    assign_public_ip = var.ecs_service_assign_public_ip
  }

  service_registries {
    registry_arn = aws_service_discovery_service.squid.arn
  }
}

resource "aws_cloudwatch_log_group" "squid" {
  name              = format("ecs/%s",var.name)
  retention_in_days = 30
  tags = var.tags
}
