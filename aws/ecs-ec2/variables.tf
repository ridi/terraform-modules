variable "cluster_name" {
  description = "Name of ECS cluster to deploy this ECS service on"
  type        = string
}

variable "service_name" {
  description = "Name of this ECS service"
  type        = string
}

variable "alb_target_group_name" {
  description = "Name of ALB target group. if doesn't use ALB, set this null"
  type        = string
  default     = null
}

variable "alb_container_name" {
  description = "Name of container bound to ALB target group"
  type        = string
  default     = "app"
}

variable "alb_container_port" {
  description = "Port of container bound to ALB target group"
  type        = number
  default     = 80
}

variable "iam_exec_role_arn" {
  description = "ARN of IAM role to execute this task"
  default     = null
}

variable "container_definitions" {
  description = "Definitions of each container. (See https://docs.aws.amazon.com/ko_kr/AmazonECS/latest/developerguide/create-task-definition.html)"
  type        = list(map(string))
}

variable "task_num" {
  description = "Number of tasks to be deployed"
  type        = number
  default     = 2
}

variable "deployment_min_percent" {
  description = "Lower limit of tasks as a percentage"
  type        = number
  default     = 50
}

variable "deployment_max_percent" {
  description = "Upper limit of tasks as a percentage"
  type        = number
  default     = 200
}
