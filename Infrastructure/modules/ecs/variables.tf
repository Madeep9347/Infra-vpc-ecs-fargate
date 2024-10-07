variable "region" {
  description = "The AWS region to deploy to"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID to deploy resources into"
  type        = string
}

variable "public_subnets" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "private_subnets" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "auth_container_image" {
  description = "Container image for the Auth ECS task"
  type        = string
}

variable "environxchange_container_image" {
  description = "Container image for the Environxchange ECS task"
  type        = string
}
