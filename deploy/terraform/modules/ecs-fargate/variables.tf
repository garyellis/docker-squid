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

variable "create_ecs_cluster" {
  description = "Creates the ECS cluster when true"
  type        = bool
  default     = true
}

variable "ecs_cluster_name" {
  description = "The ecs cluster name"
  type        = string
}

variable "container_def_image" {
  description = "The ecs container definition docker image"
  type        = string
  default     = "529332856614.dkr.ecr.us-west-2.amazonaws.com/garyellis/docker-squid:4.9"
}

variable "container_def_environment" {
  description = "The ecs container definition environment variables"
  type        = list(map(string))
  default     = [
    { name = "SELFSIGNED_CA_ENABLED", value = "true" },
    { name = "WHITELIST_FROM_ENV_ENABLED", value = "true" }
  ]
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

variable "ecs_service_assign_public_ip" {
  description = ""
  type        = bool
  default     = false
}

variable "ecs_service_desired_count" {
  description = "desired count of containers"
  type        = number
  default     = 2
}

variable "ecs_service_security_group_attachments" {
  description = "The ECS task definition security group attachments"
  type        = list(string)
}

variable "ecs_service_subnets" {
  description = "The ECS task definition subnet ids"
  type        = list(string)
  default     = []
}

variable "create_service_discovery_dns_namespace" {
  description = "Create the service discovery dns namespace"
  type        = string
  default     = ""
}

variable "service_discovery_private_dns_namespace_id" {
  description = "An existing cloud mapper namespace id"
  type        = string
  default     = ""
}

variable "service_discovery_private_dns_namespace_name" {
  description = "The route53 private hosted zone name created by cloud mapper"
  type        = string
  default     = "" 
}

variable "service_discovery_private_dns_namespace_description" {
  description = "The cloud mapper private dns zone description"
  type        = string
  default     = ""
}

variable "service_discovery_private_dns_namespace_vpc_id" {
  description = "The cloud mapper target vpc id"
  type        = string
  default     = ""
}

variable "tags" {
  description = "A map of tags applied to all taggable resources"
  type        = map(string)
  default     = {}
}
