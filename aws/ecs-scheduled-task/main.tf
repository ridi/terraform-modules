locals {
  requires_compatibilities = var.launch_type == "FARGATE" ? ["FARGATE"] : []

  task_cpu          = var.task_cpu == null ? (var.launch_type == "FARGATE" ? 256 : null) : var.task_cpu
  task_memory       = var.task_memory == null ? (var.launch_type == "FARGATE" ? 512 : null) : var.task_memory
  task_network_mode = var.task_network_mode == null ? (var.launch_type == "FARGATE" ? "awsvpc" : null) : var.task_network_mode

  awsvpc_subnet_ids       = var.awsvpc_subnet_ids == null ? (local.task_network_mode == "awsvpc" ? [] : null) : var.awsvpc_subnet_ids
  awsvpc_security_groups  = var.awsvpc_security_groups == null ? (local.task_network_mode == "awsvpc" ? [] : null) : var.awsvpc_security_groups
  awsvpc_assign_public_ip = var.awsvpc_assign_public_ip == null ? (local.task_network_mode == "awsvpc" ? false : null) : var.awsvpc_assign_public_ip
}

resource "aws_iam_role" "this" {
  count = var.iam_event_role_arn == null ? 1 : 0

  name        = "role-event-${var.name}"
  description = "The role for scheduled event '${var.name}'"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "this" {
  count = var.iam_event_role_arn == null ? 1 : 0

  name        = "policy-allow-${var.name}-run-task"
  description = "The policy allowing scheduled event '${var.name}' to run target ECS task"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "iam:PassRole"
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = "ecs:RunTask"
        Resource = var.task_definition_arn == null ? aws_ecs_task_definition.this.*.arn[0] : var.task_definition_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "this" {
  count = var.iam_event_role_arn == null ? 1 : 0

  role       = aws_iam_role.this.*.name[0]
  policy_arn = aws_iam_policy.this.*.arn[0]
}

resource "aws_cloudwatch_event_rule" "this" {
  name                = var.name
  description         = var.description == null ? "The scheduled event '${var.name}' to run target ECS task" : var.description
  schedule_expression = var.schedule_expression
  is_enabled          = var.is_enabled
}

resource "aws_cloudwatch_event_target" "this" {
  rule     = aws_cloudwatch_event_rule.this.name
  arn      = var.cluster_arn
  role_arn = var.iam_event_role_arn == null ? aws_iam_role.this.*.arn[0] : var.iam_event_role_arn

  ecs_target {
    launch_type         = var.launch_type
    task_definition_arn = var.task_definition_arn == null ? aws_ecs_task_definition.this.*.arn[0] : var.task_definition_arn
    task_count          = var.task_num

    dynamic "network_configuration" {
      for_each = local.task_network_mode != "awsvpc" ? [] : [local.awsvpc_subnet_ids]

      content {
        subnets          = network_configuration.value
        security_groups  = local.awsvpc_security_groups
        assign_public_ip = local.awsvpc_assign_public_ip
      }
    }
  }

  input = var.container_overrides == null ? null : jsonencode({
    containerOverrides = var.container_overrides
  })
}

resource "aws_ecs_task_definition" "this" {
  count = var.task_definition_arn == null ? 1 : 0

  family = var.name

  execution_role_arn = var.iam_exec_role_arn
  task_role_arn      = var.iam_task_role_arn

  requires_compatibilities = local.requires_compatibilities
  cpu                      = local.task_cpu
  memory                   = local.task_memory
  network_mode             = local.task_network_mode

  container_definitions = jsonencode(var.container_definitions)
}
