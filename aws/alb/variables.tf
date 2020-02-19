locals {
  ssl_policy = "ELBSecurityPolicy-2016-08"
}

variable "name" {
  description = "The name of ALB"
}

variable "vpc_id" {
  description = "The ID of VPC where default target groups are created"
}

variable "subnet_ids" {
  description = "The ID of subnets where ALB is created"
  type        = "list"
}

variable "security_group_ids" {
  description = "The ID of security groups of ALB"
  type        = "list"
}

variable "tags" {
  description = "The tags to assign to all resources"
  type        = "map"
  default     = {}
}

variable "log_enable" {
  description = "Write ALB log to S3 bucket"
  default     = false
}

variable "log_bucket" {
  description = "The name of S3 bucket for logging"
  default     = null
}

variable "log_bucket_prefix" {
  description = "The prefix of log data on S3 bucket"
  default     = null
}

variable "target_groups" {
  description = "The config values for multiple target groups"
  type        = any
  # map({
  #   instance_group_A = {
  #     type         = "instance"
  #     protocol     = string
  #     port         = string
  #     health_check = object({ (optional)
  #       enabled             = bool (default = true)
  #       healthy_threshold   = number (default = 2)
  #       interval            = number (default = 10)
  #       matcher             = string (default = "200-399")
  #       path                = string (default = "/health")
  #       timeout             = number (default = 5)
  #       unhealthy_threshold = number (default = 5)
  #     })
  #   }
  #   or
  #   lambda_group_B = {
  #     type              = "lambda"
  #     lambda_func_name  = string
  #     lambda_arn        = string
  #     health_check = object({ (optional)
  #       enabled             = bool (default = true)
  #       healthy_threshold   = number (default = 2)
  #       interval            = number (default = 10)
  #       matcher             = string (default = "200-399")
  #       path                = string (default = "/health")
  #       timeout             = number (default = 5)
  #       unhealthy_threshold = number (default = 5)
  #     })
  # })

  default = {}
}

variable "listeners" {
  description = "The config values for multiple listeners and listener rules"
  type        = any
  # map({
  #   $PORT_NUM = {
  #     protocol  = string (default = "HTTP")
  #     cert_arns = list(string) (optional)
  #     rules = {
  #       $RULE_NAME = {
  #         priority = number
  #         condition = {
  #           host-header  = list
  #           path-pattern = list
  #         }
  #         action = {
  #           type              = "forward"
  #           target_group_name = string
  #         }
  #         OR
  #         action = {
  #           type          = "fixed_response"
  #           content_type  = string
  #           message_bocy  = string
  #           status_code   = string
  #         }
  #       }
  #     }
  #     default_action = {
  #       type        = "redirect"
  #       protocol    = string (default = "#{protocol}")
  #       port        = number (default = #{port})
  #       host        = string (default = "#{host}")
  #       path        = string (default = "/#{path}")
  #       query       = string (default = "#{query}")
  #       status_code = number (default = "301")
  #     }
  #     OR
  #     default_action = {
  #       type         = "fixed-response"
  #       content_type = string (default = "text/plain")
  #       message_body = number (default = "")
  #       status_code  = number (default = "200")
  #     }
  #   }
  # })

  default = {}
}

variable "metrix_alarm_actions" {
  description = "The actions of CloudWatch metrix alarm"
  type        = list(string)
  default     = []
}
