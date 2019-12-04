locals {
  # { cert_arn => [port1, port2] }
  listener_certs = { for cert in flatten([for port, listener in var.listeners :
    [for index, cert_arn in lookup(listener, "cert_arns", []) :
      {
        name = "${port}-${index}"
        port = port
        arn  = cert_arn
      }
    ]
    ]) :
    cert.name => cert
  }

  # { rule_name => forward_rule }
  foward_rules = { for foward_rule in flatten([for port, listener in var.listeners :
    [for name, rule in lookup(listener, "rules", {}) :
      {
        name      = name
        port      = port
        priority  = lookup(rule, "priority", null)
        condition = rule.condition
        action = {
          target_group_name = rule.action.target_group_name
        }
      } if rule.action.type == "forward"
    ]
    ]) :
    foward_rule.name => foward_rule
  }

  # { rule_name => fixed_response_rule }
  fixed_response_rules = { for fixed_response_rule in flatten([for port, listener in var.listeners :
    [for name, rule in lookup(listener, "rules", {}) :
      {
        name      = name
        port      = port
        priority  = lookup(rule, "priority", null)
        condition = rule.condition
        action = {
          content_type = lookup(rule.action, "content_type", "text/plain")
          message_body = lookup(rule.action, "message_body", "")
          status_code  = lookup(rule.action, "status_code", "200")
        }
      } if rule.action.type == "fixed-response"
    ]
    ]) :
    fixed_response_rule.name => fixed_response_rule
  }

  # { target_group_name => instance_target_group }
  instance_target_groups = { for name, target_group in var.target_groups :
    name => {
      protocol = lookup(target_group, "protocol", "HTTP")
      port     = lookup(target_group, "port", 80)
      health_check = merge({
        enabled             = true
        healthy_threshold   = 2
        interval            = 10
        matcher             = "200-399"
        path                = "/health"
        timeout             = 5
        unhealthy_threshold = 5
      }, lookup(target_group, "health_check", {}))
    } if target_group.type == "instance"
  }

  # { target_group_name => lambda_target_group }
  lambda_target_groups = { for name, target_group in var.target_groups :
    name => {
      protocol         = lookup(target_group, "protocol", "HTTP")
      lambda_func_name = target_group.lambda_func_name
      lambda_arn       = target_group.lambda_arn
      health_check = merge({
        enabled             = true
        healthy_threshold   = 2
        interval            = 10
        matcher             = "200-399"
        path                = "/health"
        timeout             = 5
        unhealthy_threshold = 5
      }, lookup(target_group, "health_check", {}))
    } if target_group.type == "lambda"
  }

  # { target_group_name => health_checking_target_group }
  health_checking_target_groups = length(var.metrix_alarm_actions) > 0 ? { for name, target_group in var.target_groups :
    name => target_group if lookup(target_group, "health_check", false) == true
  } : {}
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
      for_each = (each.value.default_action.type == "redirect" ?
      [each.value.default_action] : [])

      content {
        protocol    = lookup(redirect.value, "protocol", "#{protocol}")
        port        = lookup(redirect.value, "port", "#{port}")
        host        = lookup(redirect.value, "host", "#{host}")
        path        = lookup(redirect.value, "path", "/#{path}")
        query       = lookup(redirect.value, "query", "#{query}")
        status_code = "HTTP_${lookup(redirect.value, "status_code", "301")}"
      }
    }

    dynamic "fixed_response" {
      for_each = (each.value.default_action.type == "fixed-response" ?
      [each.value.default_action] : [])

      content {
        content_type = lookup(fixed_response.value, "content_type", "text/plain")
        message_body = lookup(fixed_response.value, "messasge_body", "")
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
resource "aws_alb_target_group" "instance" {
  for_each = local.instance_target_groups

  name                 = each.key
  target_type          = "instance"
  vpc_id               = var.vpc_id
  protocol             = each.value.protocol
  port                 = each.value.port
  deregistration_delay = 30

  dynamic "health_check" {
    for_each = [each.value.health_check]

    content {
      enabled             = health_check.value.enabled
      healthy_threshold   = health_check.value.healthy_threshold
      interval            = health_check.value.interval
      matcher             = health_check.value.matcher
      path                = health_check.value.path
      timeout             = health_check.value.timeout
      unhealthy_threshold = health_check.value.unhealthy_threshold
    }
  }

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_alb_target_group" "lambda" {
  for_each = local.lambda_target_groups

  name                 = each.key
  target_type          = "lambda"
  deregistration_delay = 30

  dynamic "health_check" {
    for_each = [each.value.health_check]

    content {
      enabled             = health_check.value.enabled
      healthy_threshold   = health_check.value.healthy_threshold
      interval            = health_check.value.interval
      matcher             = health_check.value.matcher
      path                = health_check.value.path
      timeout             = health_check.value.timeout
      unhealthy_threshold = health_check.value.unhealthy_threshold
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
  source_arn    = aws_alb_target_group.lambda[each.key].arn
  function_name = each.value.lambda_func_name
}

resource "aws_alb_target_group_attachment" "lambda" {
  for_each = local.lambda_target_groups

  target_group_arn = aws_alb_target_group.lambda[each.key].arn
  target_id        = each.value.lambda_arn

  depends_on = [aws_lambda_permission.lambda]
}

# ------------------------
# ALB listener rules
# ------------------------
resource "aws_alb_listener_rule" "forward" {
  for_each = local.foward_rules

  priority     = each.value.priority
  listener_arn = aws_alb_listener.this[each.value.port].arn

  dynamic "condition" {
    for_each = each.value.condition

    content {
      field  = condition.key
      values = condition.value
    }
  }

  action {
    type             = "forward"
    target_group_arn = merge(aws_alb_target_group.instance, aws_alb_target_group.lambda)[each.value.action.target_group_name].arn
  }
}

resource "aws_alb_listener_rule" "fixed_response" {
  for_each = local.fixed_response_rules

  priority     = each.value.priority
  listener_arn = aws_alb_listener.this[each.value.port].arn

  dynamic "condition" {
    for_each = each.value.condition

    content {
      field  = condition.key
      values = condition.value
    }
  }

  action {
    type = "fixed-response"

    fixed_response {
      content_type = each.value.action.content_type
      message_body = each.value.action.message_body
      status_code  = each.value.action.status_code
    }
  }
}

# ------------------------
# CloudWatch metric alarms
# ------------------------
resource "aws_cloudwatch_metric_alarm" "unhealty_host" {
  for_each = local.health_checking_target_groups

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
    TargetGroup  = merge(aws_alb_target_group.instance, aws_alb_target_group.lambda)[each.key].arn_suffix
  }

  actions_enabled = true
  alarm_actions   = var.metrix_alarm_actions
}
