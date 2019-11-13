name                    = "my-codebuild-project-name"
description             = "my codebuild project description"
iam_policy_attachments  = []
source_s3_bucket_name   = "ews-works"
source_s3_bucket_prefix = "codebuild/"

tags                    = {}

environment_variables   = []
codebuild_source        = [{
  "type"     = "S3"
  location   = "ews-works/codebuild/docker-squid.zip"
}]
