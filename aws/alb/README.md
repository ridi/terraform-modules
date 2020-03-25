# alb

## Usage

```hcl
module "alb" {
  source = "github.com/ridi/terraform-modules//aws/alb"

  name       = "my-alb"
  vpc_id     = data.aws_vpc.my_vpc.id
  subnet_ids = data.aws_subnet_ids.my_subnet.ids

  security_group_ids = [
    module.sg_alb.this_security_group_id,
  ]

  target_groups = {
    lambda-api = {
      type             = "lambda"
      lambda_func_name = data.aws_lambda_function.my_lambda.function_name
      lambda_arn       = data.aws_lambda_function.my_lambda.arn
      health_check     = { enabled = false }
      http5xx_alarm    = { enabled = false }
    },
    instance-api = {
      type          = "instance"
      port          = 80
      health_check  = { path = "/health" }
      http5xx_alarm = { threshold = 5, period = 600 }
    },
  }

  listeners = {
    80 = {
      protocol = "HTTP"
      default_action = {
        type        = "redirect"
        protocol    = "HTTPS"
        port        = 443
        status_code = 301
      }
    },
    443 = {
      protocol  = "HTTPS"
      cert_arns = data.aws_acm_certificate.cert.*.arn

      rules = {
        robots = {
          priority  = 1
          condition = { path-pattern = ["/robots.txt"] }
          action = {
            type           = "fixed-response"
            fixed_response = {
                content_type = "text/plain"
                message_body = "User-agent: *\nDisallow: /\n"
                status_code  = "200"
            }
          }
        },
        service1-api = {
          priority  = 2
          condition = {
            host-header  = { values = ["api.my-service.com"] }
            path-pattern = { values = ["/foo/*"] }
          }
          action = {
            type = "forward"
            target_group_name = "lambda-api"
          }
        },
        service2-api = {
          priority  = 3
          condition = {
            host-header  = { values = ["api.my-service.com"] }
            path-pattern = { values = ["/bar/*"] }
          action = {
            type = "forward"
            target_group_name = "instance-api"
          }
        },
      }

      default_action = {
        type = "redirect"
        redirect = {
          protocol    = "HTTPS"
          port        = 443
          host        = "my-service.com"
          path        = "/error/400"
          query       = ""
          status_code = 302
        }
        }
      }
    },
  }
}
```

## Input Variables

### Common

- `tags`: The tags to assign to all resources

### VPC

- `vpc_id`: The ID of VPC where default target groups are created
- `subnet_ids`: The ID of subnets where ALB is created
- `security_group_ids`: The ID of security groups of ALB

### ALB

- `name`: The name of ALB

- `target_groups`: The config values for multiple target groups in form of the below

```hcl
{
  # Instance type
  instance_group_A = {
    type     = "instance"
    protocol = string
    port     = string
    health_check = { (optional)
      enabled             = bool (default = true)
      healthy_threshold   = number (default = 2)
      interval            = number (default = 10)
      matcher             = string (default = "200-399")
      path                = string (default = "/health")
      timeout             = number (default = 5)
      unhealthy_threshold = number (default = 5)
    }
    http5xx_alarm = { (optional)
      enabled            = bool (default = true)
      threshold          = number (default = 0)
      period             = number (default = 300)
      evaluation_periods = number (default = 1)
    }
  }

  # Lambda type
  lambda_group_B = {
    type             = "lambda"
    lambda_func_name = string
    lambda_arn       = string
    health_check = { (optional)
      enabled             = bool (default = true)
      healthy_threshold   = number (default = 2)
      interval            = number (default = 10)
      matcher             = string (default = "200-399")
      path                = string (default = "/health")
      timeout             = number (default = 5)
      unhealthy_threshold = number (default = 5)
    }
  }
}
```

- `listeners`: The config values for multiple listeners and listener rules in form of the below

```hcl
listeners = {
  80 (port number) = {
    protocol = string (default = "HTTP")
    cert_arns = list (optional)
    rules = {
      RULE_NAME = {
        priority = number
        condition = {
          host-header = { values = list }
          path-pattern = { values = list }
        }
        # Forward type
        action = {
          type = "forward"
          target_group_name = string
        }
        # Fixed response type
        action = {
          type = "fixed_response"
          fixed_response = {
            content_type = string
            message_bocy = string
            status_code = string
          }
        }
      }
    }
    # Redirect type
    default_action = {
      type = "redirect"
      redirect = {
        protocol    = string (default = "#{protocol}")
        port        = number (default = "#{port}")
        host        = string (default = "#{host}")
        path        = string (default = "/#{path}")
        query       = string (default = "#{query}")
        status_code = number (default = "301")
      }
    }
    # Fixed response type
    default_action = {
      type = "fixed-response"
      fixed_response = {
        content_type = string (default = "text/plain")
        message_body = number (default = "")
        status_code  = number (default = "200")
      }
    }
  }
}
```

### S3

- `log_enable`: Write ALB log to S3 bucket
- `log_bucket`: The name of S3 bucket for logging
- `log_bucket_prefix`: The prefix of log data on S3 bucket

### CloudWatch

- `metrix_alarm_actions`: The actions of CloudWatch metrix alarm
