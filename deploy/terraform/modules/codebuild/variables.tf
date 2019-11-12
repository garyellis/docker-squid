variable "name" {
  description = "A unique identifier applied to all resources"
  type        = string
}

variable "description" {
  description = "the build description"
  type        = string
}

variable "iam_policy_attachments" {
  description = "A list of policies attached to the codebuild service role"
  type        = list(string)
  default     = []
}

variable "iam_policy_attachments_count" {
  description = "The number of iam role policy attachments. (the count cannot be dynamically computed)"
  type        = number
  default     = 0
}

variable "source_s3_bucket_name" {
  description = "code build source s3 bucket (optional)"
  type        = string
  default     = ""
}

variable "source_s3_bucket_prefix" {
  description = "code build source s3 bucket (optional)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "A map of tags applied to all taggable resources"
  type        = map(string)
  default     = {}
}

variable "environment_compute_type" {
  description = "The environment compute type. Possible values are BUILD_GENERAL1_SMALL, BUILD_GENERAL1_MEDIUM, BUILD_GENERAL1_LARGE"
  type        = string
  default     = "BUILD_GENERAL1_SMALL"
}

variable "environment_docker_image" {
  description = "The environment docker image."
  type        = string
  default     = "aws/codebuild/standard:2.0"
}

variable "environment_privileged_mode" {
  description = "Enable priviledged mode. enabled for docker builds"
  type        = bool
  default     = true
}

variable "environment_type" {
  description = "The environment type. Possible values are LINUX_CONTAINER and WINDOWS_CONTAINER"
  type        = string
  default     = "LINUX_CONTAINER"
}


variable "environment_variables" {
  description = "A list of environment variable maps"
  type        = list(map(string))
  default     = []
}

variable "codebuild_source" {
  description = "The codebuild source configuration"
  type        = list(map(string))
  default     = []
}
