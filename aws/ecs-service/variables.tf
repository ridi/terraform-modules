variable "cluster_name" {
  description = "Name of ECS cluster to deploy ECS service on"
  type        = string
}

variable "service_name" {
  description = "Name of this ECS service"
  type        = string
}

variable "launch_type" {
  description = "The launch type on which to run your service. ('EC2' or 'FARGATE')"
  type        = string
  default     = "EC2"
}

variable "task_definition_arn" {
  description = "The arn of task definition. If not set, creates new one. (container_definitions is required)"
  type        = string
  default     = null
}

variable "task_cpu" {
  description = "The number of cpu units used by the task. (used in Fargate)"
  type        = number
  default     = null
}

variable "task_memory" {
  description = "The amount (in MB) of memory used by the task. (used in Fargate)"
  type        = number
  default     = null
}

variable "task_network_mode" {
  description = "The Docker networking mode to use for the containers in the task. ('none', 'bridge', 'awsvpc', 'host')"
  type        = string
  default     = null
}

variable "awsvpc_subnet_ids" {
  description = "The subnets associated with the task or service (task_network_mode)"
  type        = list(string)
  default     = null
}

variable "awsvpc_security_groups" {
  description = "The security groups associated with the task or service"
  type        = list(string)
  default     = null
}

variable "awsvpc_assign_public_ip" {
  description = "Whether assigns a public IP address to the ENI or not"
  type        = bool
  default     = null
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
  description = "ARN of IAM role to execute ECS task"
  default     = null
}

variable "iam_task_role_arn" {
  description = "ARN of IAM role of ECS task"
  default     = null
}

variable "container_definitions" {
  description = "Definitions of each container. (See https://docs.aws.amazon.com/ko_kr/AmazonECS/latest/developerguide/create-task-definition.html)"
  type        = any
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

variable "volumes" {
  description = "Docker volume block list"
  type        = list(object({
    name      = string
    host_path = string
  }))
  default     = []
}
