variable "create" {
  description = "Whether to create this resources or not"
  type        = bool
  default     = true
}

variable "tags" {
  description = "The tags to assign to all resources"
  type        = map(string)
  default     = {}
}

variable "ecs_cluster_name" {
  description = "The name of ECS cluster"
  type        = string
  default     = null
}

variable "asg_availability_zones" {
  description = "The availability zones where autoscale group instances are created"
  type        = list(string)
  default     = []
}

variable "asg_subnet_ids" {
  description = "The list of subnet IDs associate with autoscale instances"
  type        = list(string)
  default     = []
}

variable "asg_min_size" {
  description = "The minimum number of autoscale instances."
  type        = number
  default     = 0
}

variable "asg_max_size" {
  description = "The maximum number of autoscale instances."
  type        = number
  default     = 1
}

variable "asg_desired_capacity" {
  description = "The decired number of autoscale instances."
  type        = number
  default     = 0
}

variable "asg_termination_policies" {
  description = "The policies that choose which instance to terminate first"
  type        = list(string)
  default     = ["OldestInstance"]
}

variable "ec2_name" {
  description = "The name tag attached to scaled instance"
  type        = string
  default     = null
}

variable "ec2_ami_id" {
  description = "The id of the AMI used for the autoscale instances"
  type        = string
  default     = null
}

variable "ec2_timezone" {
  description = "The timezone for the autocale instances"
  type        = string
  default     = "Asia/Seoul"
}

variable "ec2_locale" {
  description = "The locale for the autocale instances"
  type        = string
  default     = "en_US.UTF-8"
}

variable "ec2_type" {
  description = "The autoscale instance type"
  type        = string
  default     = "t2.micro"
}

variable "ec2_volume_size" {
  description = "The total size of the autoscale instance volume in gigabytes (root block size(=8GB) + EBS block size)"
  type        = number
  default     = 30
}

variable "ec2_security_group_ids" {
  description = "The list of security group ids to associate with autoscale instances"
  type        = list(string)
  default     = []
}

variable "ec2_role_policy_arns" {
  description = "The list of additional instance role policy arn"
  type        = list(string)
  default     = []
}

variable "ec2_enable_monitoring" {
  description = "If true, autoscale instance will have detailed monitoring enabled"
  default     = false
}

variable "ec2_user_data" {
  description = "The init script for EC2"
  default     = null
}

variable "metrix_alarm_actions" {
  description = "The actions of CloudWatch metrix alarm"
  type        = list(string)
  default     = []
}

variable "metrix_alarm_memory_util_threshold" {
  description = "The threshold of memory utilization CloudWatch metrix alarm"
  type        = number
  default     = 70
}

variable "metrix_alarm_memory_util_period" {
  description = "The period of memory utilization CloudWatch metrix alarm"
  type        = number
  default     = 60
}

variable "metrix_alarm_cpu_util_threshold" {
  description = "The threshold of CPU utilization CloudWatch metrix alarm"
  type        = number
  default     = 70
}

variable "metrix_alarm_cpu_util_period" {
  description = "The period of CPU utilization CloudWatch metrix alarm"
  type        = number
  default     = 60
}

variable "task_stopped_event_target_arn" {
  description = "The arn of task stopped event target"
  type        = string
  default     = null
}
