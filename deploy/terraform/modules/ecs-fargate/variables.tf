variable "name" {
  description = "A unique identifier applied to all resources"
  type        = string
}

variable "ssm_kms_key_arn" {
  description = "A KMS key arn used to decrypt ssm parameters"
  type        = string
  default     = ""
}

variable "ecs_task_iam_policy_attachment_arns_count" {
  description = ""
  type        = string
  default     = 0
}

variable "ecs_task_iam_policy_attachment_arns" {
  description = ""
  type        = list(string)
  default     = []
}

variable "squid_whitelist_ssm_parameter_name" {
  description = "The squid whitelist ssm parameter key"
  type        = string
  default     = ""
}

variable "squid_conf_ssm_parameter_name" {
  description = "The squid.conf ssm parameter key"
  type        = string
  default     = ""
}

variable "tags" {
  description = "A map of tags applied to all taggable resources"
  type        = map(string)
  default     = {}
}
