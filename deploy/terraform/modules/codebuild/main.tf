data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_iam_policy_document" "codebuild_assume_role" {
  statement {
    actions       = ["sts:AssumeRole"]
    effect        = "Allow"
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

locals {
  iam_s3_bucket_source_enabled = var.source_s3_bucket_name != "" ? [""] : []
}

data "aws_iam_policy_document" "codebuild" {
  statement {
    sid     = "CodeBuildCloudwatchLogs"
    effect  = "Allow"
    actions = [
     "logs:CreateLogGroup",
     "logs:CreateLogStream",
     "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${var.name}",
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${var.name}:*"
    ]
  }

  statement {
    sid     = "CodeBuildECRAccess"
    effect  = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:GetAuthorizationToken",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart"
    ]
    resources = ["*"]
  }

  dynamic "statement" {
    for_each = local.iam_s3_bucket_source_enabled
    content {
      sid     = "CodeBuildS3ObjectRead"
      effect  = "Allow"
      actions = [
        "s3:GetObject",
        "s3:GetObjectVersion"
      ]
      resources = [
        "arn:aws:s3:::${var.source_s3_bucket_name}/${var.source_s3_bucket_prefix}/",
        "arn:aws:s3:::${var.source_s3_bucket_name}/${var.source_s3_bucket_prefix}/*"
      ]
    }
  }

  dynamic "statement" {
    for_each = local.iam_s3_bucket_source_enabled
    content {
      sid     = "CodeBuildS3ListBucket"
      effect  = "Allow"
      actions = [
        "s3:ListBucket",
        "s3:GetBucketAcl",
        "s3:GetBucketLocation"
      ]
      resources = [
        "arn:aws:s3:::${var.source_s3_bucket_name}"
      ]
    }
  }
}

resource "aws_iam_policy" "codebuild" {
 name_prefix = format("%s-codebuild", var.name)
 policy      = data.aws_iam_policy_document.codebuild.json
}

resource "aws_iam_role" "codebuild" {
  name_prefix        = format("%s-codebuild", var.name)
  description        = "codebuild service role"
  path               = "/service-role/"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume_role.json
  tags               = merge(map("Name", format("%s-codebuild", var.name)), var.tags)
}

locals {
  codebuild_policy_arns = compact(concat(var.iam_policy_attachments, aws_iam_policy.codebuild.*.arn))
}

resource "aws_iam_role_policy_attachment" "codebuild_policy_attachments" {
  count = var.iam_policy_attachments_count + 1

  role       = aws_iam_role.codebuild.name
  policy_arn = local.codebuild_policy_arns[count.index]
}

resource "aws_codebuild_project" "codebuild" {
  name          = var.name
  description   = var.description
  build_timeout = 120
  service_role  = aws_iam_role.codebuild.arn
  tags          = var.tags

  dynamic "source" {
    for_each = var.codebuild_source
    content {
      type                = lookup(source.value, "type", null)
      #auth                = lookup(source.value, "auth", null)
      buildspec           = lookup(source.value, "buildspec", null)
      git_clone_depth     = lookup(source.value, "git_clone_depth", null)
      insecure_ssl        = lookup(source.value, "insecure_ssl", null)
      location            = lookup(source.value, "location", null)
      report_build_status = lookup(source.value, "report_build_status", null)
    }
  }

  environment {
    type            = var.environment_type
    compute_type    = var.environment_compute_type
    image           = var.environment_docker_image
    privileged_mode = var.environment_privileged_mode

    dynamic "environment_variable" {
      for_each = var.environment_variables
      content {
        name  = lookup(environment_variable, "name", null)
        value = lookup(environment_variable, "value", null)
        type  = lookup(environment_variable, "type", null)
      }
    }
  }

  artifacts {
    type = "NO_ARTIFACTS"
  }

  logs_config {
    cloudwatch_logs {
      group_name = var.name
      stream_name = "codebuild"
    }
  }
}
