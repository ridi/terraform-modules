variable "name" {
  description = "The name of the scheduling event rule and task definition (if new task is created)"
  type        = string
}

variable "description" {
  description = "The description of the scheduling event rule"
  type        = string
  default     = null
}

variable "schedule_expression" {
  description = "The scheduling expression. For example, cron(0 20 * * ? *) or rate(5 minutes)."
  type        = string
}

variable "is_enabled" {
  description = "Whether the rule should be enabled"
  type        = bool
  default     = true
}

variable "cluster_arn" {
  description = "The ARN of ECS cluster to deploy this ECS service on"
  type        = string
}

variable "launch_type" {
  description = "The launch type on which to run your service. ('EC2' or 'FARGATE')"
  type        = string
  default     = "EC2"
}

variable "task_definition_arn" {
  description = "The arn of task definition. If not set, creates new one. (requires `container_definitions`)"
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

variable "iam_event_role_arn" {
  description = "The ARN of IAM role that is used for event target invocation. If not set, creates new one"
  type        = string
  default     = null
}

variable "iam_exec_role_arn" {
  description = "The ARN of IAM role to execute ECS task"
  default     = null
}

variable "iam_task_role_arn" {
  description = "The ARN of IAM role of ECS task"
  default     = null
}

variable "container_definitions" {
  description = "The definitions of each container. (See https://docs.aws.amazon.com/ko_kr/AmazonECS/latest/developerguide/create-task-definition.html)"
  type        = any
}

variable "container_overrides" {
  description = "The definition override of containers. [{ name = 'name-of-container-to-override', 'key-to-override' = 'value', ... }, {...}]"
  type        = any
  default     = null
}

variable "task_num" {
  description = "The number of tasks to be deployed"
  type        = number
  default     = 2
}
