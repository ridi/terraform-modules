variable "cluster_name" {
  description = "The name of ECS cluster to deploy ECS service on"
  type        = string
}

variable "service_name" {
  description = "The name of this ECS service"
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

variable "load_balancers" {
  description = "The list of load balancer associations [{ target_group_arn, container_name, container_port }]"
  type = list(object({
    target_group_arn = string,
    container_name   = string,
    container_port   = number,
  }))
  default = []
}

variable "iam_exec_role_arn" {
  description = "The ARN of IAM role to execute ECS task"
  default     = null
}

variable "iam_task_role_arn" {
  description = "The ARN of IAM role of ECS task"
  default     = null
}

variable "volumes" {
  description = "The list of Docker volume definition."
  type        = list(any)

  # array([
  #   {
  #     name      = string
  #     host_path = string (optional)
  #     docker_volume_configuration = map({ (optional)
  #       scope         = string (optional)
  #       autoprovision = bool (optional)
  #       driver        = string (optional)
  #       driver_opts   = map (optional)
  #       labels        = map (optional)
  #     })
  #   },
  # ])

  default = []
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

variable "metric_alarm_actions" {
  description = "The actions of CloudWatch metric alarm"
  type        = list(string)
  default     = []
}

variable "metric_alarm_memory_util_threshold" {
  description = "The threshold of memory utilization CloudWatch metric alarm"
  type        = number
  default     = 80
}

variable "metric_alarm_memory_util_period" {
  description = "The period of memory utilization CloudWatch metric alarm"
  type        = number
  default     = 60
}

variable "metric_alarm_cpu_util_threshold" {
  description = "The threshold of CPU utilization CloudWatch metric alarm"
  type        = number
  default     = 80
}

variable "metric_alarm_cpu_util_period" {
  description = "The period of CPU utilization CloudWatch metric alarm"
  type        = number
  default     = 60
}
