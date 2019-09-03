locals {
  requires_compatibilities = var.launch_type == "FARGATE" ? ["FARGATE"] : []

  task_cpu          = var.task_cpu == null ? (var.launch_type == "FARGATE" ? 256 : null) : var.task_cpu
  task_memory       = var.task_memory == null ? (var.launch_type == "FARGATE" ? 512 : null) : var.task_memory
  task_network_mode = var.task_network_mode == null ? (var.launch_type == "FARGATE" ? "awsvpc" : null) : var.task_network_mode

  awsvpc_subnet_ids       = var.awsvpc_subnet_ids == null ? (local.task_network_mode == "awsvpc" ? [] : null) : var.awsvpc_subnet_ids
  awsvpc_security_groups  = var.awsvpc_security_groups == null ? (local.task_network_mode == "awsvpc" ? [] : null) : var.awsvpc_security_groups
  awsvpc_assign_public_ip = var.awsvpc_assign_public_ip == null ? (local.task_network_mode == "awsvpc" ? false : null) : var.awsvpc_assign_public_ip
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

resource "aws_cloudwatch_event_rule" "this" {
  name                = var.name
  description         = var.description
  schedule_expression = var.schedule_expression
  is_enabled          = var.is_enabled
}

resource "aws_cloudwatch_event_target" "this" {
  rule     = aws_cloudwatch_event_rule.this.name
  arn      = var.cluster_arn
  role_arn = var.iam_event_role_arn

  ecs_target {
    launch_type = var.launch_type

    network_configuration = local.task_network_mode != "awsvpc" ? null : {
      subnets          = local.awsvpc_subnet_ids
      security_groups  = local.awsvpc_security_groups
      assign_public_ip = local.awsvpc_assign_public_ip
    }

    task_definition_arn = var.task_definition_arn == null ? aws_ecs_task_definition.this.*.arn[0] : var.task_definition_arn
    task_count          = var.task_num
  }

  input = var.container_overrides == null ? null : jsonencode({
    containerOverrides = var.container_overrides
  })
}
