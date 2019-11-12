name                    = "tf-codebuild"
description             = "code pipeline project creation"
iam_policy_attachments  = []
source_s3_bucket_name   = "ews-works"
source_s3_bucket_prefix = "codebuild/docker-squid"

tags                    = {}

environment_variables   = []
codebuild_source        = [{
  "type"     = "S3"
  location   = "ews-works/codebuild/docker-squid/"
}]
