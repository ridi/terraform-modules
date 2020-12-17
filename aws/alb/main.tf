locals {
  # { ${PORT}-${INDEX} => cert_options }
  listener_certs = { for listener_cert in flatten([for port, listener in var.listeners :
    [for index, cert_arn in lookup(listener, "cert_arns", []) :
      {
        name = "${port}-${index}"
        port = port
        arn  = cert_arn
      }
    ]
    ]) :
    listener_cert.name => listener_cert
  }

  # { listener_rule_name => listener_rule_oprions }
  listener_rules = { for listener_rule in flatten([for port, listener in var.listeners :
    [for name, rule in lookup(listener, "rules", {}) :
      {
        name      = name
        port      = port
        priority  = lookup(rule, "priority", null)
        condition = rule.condition
        action    = rule.action
      }
    ]
    ]) :
    listener_rule.name => listener_rule
  }

  # { target_group_name => lambda_options }
  lambda_target_groups = { for name, target_group in var.target_groups :
    name => {
      lambda_func_name = target_group.lambda_func_name
      lambda_arn       = target_group.lambda_arn
      lambda_qualifier = lookup(target_group, "lambda_qualifier", null)
    } if target_group.type == "lambda"
  }

  # { target_group_name => health_check_options }
  health_checking_target_groups = { for name, target_group in var.target_groups :
    name => target_group.health_check
    if lookup(lookup(target_group, "health_check", {}), "enabled", true)
  }

  # { target_group_name => http5xx_alarm_options }
  http5xx_alarm_target_groups = { for name, target_group in var.target_groups :
    name => {
      threshold          = lookup(target_group.http5xx_alarm, "threshold", 0)
      period             = lookup(target_group.http5xx_alarm, "period", 300)
      evaluation_periods = lookup(target_group.http5xx_alarm, "evaluation_periods", 1)
    } if lookup(lookup(target_group, "http5xx_alarm", {}), "enabled", true)
  }
}

# ------------------------
# ALB
# ------------------------
resource "aws_alb" "this" {
  name            = var.name
  subnets         = var.subnet_ids
  security_groups = var.security_group_ids
  internal        = false

  dynamic "access_logs" {
    for_each = (var.log_bucket == null ? [] : [var.log_bucket])

    content {
      bucket  = access_logs.value
      prefix  = var.log_bucket_prefix
      enabled = var.log_enable
    }
  }

  tags = var.tags
}

# ------------------------
# ALB listeners
# ------------------------
resource "aws_alb_listener" "this" {
  for_each = var.listeners

  load_balancer_arn = aws_alb.this.arn

  port            = each.key
  protocol        = each.value.protocol
  certificate_arn = lookup(each.value, "cert_arns", [null])[0]
  ssl_policy      = length(lookup(each.value, "cert_arns", [])) > 0 ? "ELBSecurityPolicy-2016-08" : null

  default_action {
    type = each.value.default_action.type

    dynamic "redirect" {
      for_each = (each.value.default_action.type == "redirect" ? [each.value.default_action.redirect] : [])

      content {
        protocol    = lookup(redirect.value, "protocol", "#{protocol}")
        port        = lookup(redirect.value, "port", "#{port}")
        host        = lookup(redirect.value, "host", "#{host}")
        path        = lookup(redirect.value, "path", "/#{path}")
        query       = lookup(redirect.value, "query", "#{query}")
        status_code = "HTTP_${lookup(redirect.value, "status_code", "302")}"
      }
    }

    dynamic "fixed_response" {
      for_each = (each.value.default_action.type == "fixed-response" ? [each.value.default_action.fixed_response] : [])
      content {
        content_type = lookup(fixed_response.value, "content_type", "text/plain")
        message_body = lookup(fixed_response.value, "message_body", "")
        status_code  = lookup(fixed_response.value, "status_code", "200")
      }
    }
  }
}

# ------------------------
# ALB listener certificates
# ------------------------
resource "aws_alb_listener_certificate" "this" {
  for_each = local.listener_certs

  certificate_arn = each.value.arn
  listener_arn    = aws_alb_listener.this[each.value.port].arn
}

# ------------------------
# ALB target groups
# ------------------------
resource "aws_alb_target_group" "this" {
  for_each = var.target_groups

  name                 = each.key
  target_type          = lookup(each.value, "type", "instance")
  deregistration_delay = 30

  # non-lambda type only options
  vpc_id   = lookup(each.value, "type", "instance") != "lambda" ? var.vpc_id : null
  protocol = lookup(each.value, "type", "instance") != "lambda" ? lookup(each.value, "protocol", "HTTP") : null
  port     = lookup(each.value, "type", "instance") != "lambda" ? lookup(each.value, "port", 80) : null

  dynamic "health_check" {
    for_each = lookup(each.value, "health_check", false) == false ? [] : [each.value.health_check]
    content {
      enabled             = lookup(health_check.value, "enabled", true)
      healthy_threshold   = lookup(health_check.value, "healthy_threshold", 2)
      interval            = lookup(health_check.value, "interval", 10)
      matcher             = lookup(health_check.value, "matcher", "200-399")
      path                = lookup(health_check.value, "path", "/health")
      timeout             = lookup(health_check.value, "timeout", 5)
      unhealthy_threshold = lookup(health_check.value, "unhealthy_threshold", 5)
    }
  }

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lambda_permission" "lambda" {
  for_each = local.lambda_target_groups

  principal     = "elasticloadbalancing.amazonaws.com"
  action        = "lambda:InvokeFunction"
  source_arn    = aws_alb_target_group.this[each.key].arn
  function_name = each.value.lambda_func_name
  qualifier     = each.value.lambda_qualifier
}

resource "aws_alb_target_group_attachment" "lambda" {
  for_each = local.lambda_target_groups

  target_group_arn = aws_alb_target_group.this[each.key].arn
  target_id        = each.value.lambda_qualifier == null ? each.value.lambda_arn : "${each.value.lambda_arn}:${each.value.lambda_qualifier}"

  depends_on = [aws_lambda_permission.lambda]
}

# ------------------------
# ALB listener rules
# ------------------------
resource "aws_alb_listener_rule" "this" {
  for_each = local.listener_rules

  priority     = each.value.priority
  listener_arn = aws_alb_listener.this[each.value.port].arn

  dynamic "condition" {
    for_each = each.value.condition
    content {
      dynamic "host_header" {
        for_each = condition.key == "host_header" ? [condition.value] : []
        content {
          values = host_header.value.values
        }
      }

      dynamic "http_header" {
        for_each = condition.key == "http_header" ? [condition.value] : []
        content {
          http_header_name = http_header.value.http_header_name
          values           = http_header.value.values
        }
      }

      dynamic "http_request_method" {
        for_each = condition.key == "http_request_method" ? [condition.value] : []
        content {
          values = http_request_method.value.values
        }
      }

      dynamic "path_pattern" {
        for_each = condition.key == "path_pattern" ? [condition.value] : []
        content {
          values = path_pattern.value.values
        }
      }

      dynamic "query_string" {
        for_each = condition.key == "query_string" ? condition.value.values : []
        content {
          key   = lookup(query_string.value, "key", null)
          value = query_string.value.value
        }
      }

      dynamic "source_ip" {
        for_each = condition.key == "source_ip" ? [condition.value] : []
        content {
          values = source_ip.value.values
        }
      }
    }
  }

  action {
    type             = each.value.action.type
    target_group_arn = each.value.action.type == "forward" ? aws_alb_target_group.this[each.value.action.target_group_name].arn : null

    dynamic "redirect" {
      for_each = each.value.action.type == "redirect" ? [each.value.action.redirect] : []
      content {
        protocol    = lookup(redirect.value, "protocol", "#{protocol}")
        port        = lookup(redirect.value, "port", "#{port}")
        host        = lookup(redirect.value, "host", "#{host}")
        path        = lookup(redirect.value, "path", "/#{path}")
        query       = lookup(redirect.value, "query", "#{query}")
        status_code = "HTTP_${lookup(redirect.value, "status_code", "302")}"
      }
    }

    dynamic "fixed_response" {
      for_each = each.value.action.type == "fixed-response" ? [each.value.action.fixed_response] : []
      content {
        content_type = lookup(fixed_response.value, "content_type", "text/html")
        message_body = lookup(fixed_response.value, "message_body", "")
        status_code  = lookup(fixed_response.value, "status_code", "200")
      }
    }
  }
}

# ------------------------
# CloudWatch metric alarms
# ------------------------
resource "aws_cloudwatch_metric_alarm" "unhealty_host" {
  for_each = length(var.metric_alarm_actions) > 0 ? local.health_checking_target_groups : {}

  alarm_description = "The unhealthy host count of target group '${each.key}'"

  alarm_name  = "alarm-${each.key}-unhealthy-host"
  namespace   = "AWS/ApplicationELB"
  metric_name = "UnHealthyHostCount"

  comparison_operator = "GreaterThanThreshold"
  statistic           = "Maximum"
  threshold           = 0
  period              = 60
  evaluation_periods  = 1

  dimensions = {
    LoadBalancer = aws_alb.this.arn_suffix
    TargetGroup  = aws_alb_target_group.this[each.key].arn_suffix
  }

  actions_enabled = true
  alarm_actions   = var.metric_alarm_actions
  ok_actions      = var.metric_alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "http5xx" {
  for_each = length(var.metric_alarm_actions) > 0 ? local.http5xx_alarm_target_groups : {}

  alarm_description = "The count of http 5xx response from target group '${each.key}'"

  alarm_name  = "alarm-${each.key}-target-5xx-count"
  namespace   = "AWS/ApplicationELB"
  metric_name = "HTTPCode_Target_5XX_Count"

  statistic           = "Sum"
  treat_missing_data  = "notBreaching"
  comparison_operator = "GreaterThanThreshold"

  threshold          = each.value.threshold
  period             = each.value.period
  evaluation_periods = each.value.evaluation_periods

  dimensions = {
    LoadBalancer = aws_alb.this.arn_suffix
    TargetGroup  = aws_alb_target_group.this[each.key].arn_suffix
  }

  actions_enabled = true
  alarm_actions   = var.metric_alarm_actions
  ok_actions      = var.metric_alarm_actions
}
