locals {
  task_cpu          = var.task_cpu == null ? (var.launch_type == "FARGATE" ? 256 : null) : var.task_cpu
  task_memory       = var.task_memory == null ? (var.launch_type == "FARGATE" ? 512 : null) : var.task_memory
  task_network_mode = var.task_network_mode == null ? (var.launch_type == "FARGATE" ? "awsvpc" : null) : var.task_network_mode

  awsvpc_subnet_ids       = var.awsvpc_subnet_ids == null ? (local.task_network_mode == "awsvpc" ? [] : null) : var.awsvpc_subnet_ids
  awsvpc_security_groups  = var.awsvpc_security_groups == null ? (local.task_network_mode == "awsvpc" ? [] : null) : var.awsvpc_security_groups
  awsvpc_assign_public_ip = var.awsvpc_assign_public_ip == null ? (local.task_network_mode == "awsvpc" ? false : null) : var.awsvpc_assign_public_ip
}

data "aws_lb_target_group" "this" {
  count = var.alb_target_group_name == null ? 0 : 1
  name  = var.alb_target_group_name
}

resource "aws_ecs_service" "this" {
  name            = var.service_name
  launch_type     = var.launch_type
  cluster         = var.cluster_name
  task_definition = aws_ecs_task_definition.this.arn

  desired_count                      = var.task_num
  deployment_minimum_healthy_percent = var.deployment_min_percent
  deployment_maximum_percent         = var.deployment_max_percent

  dynamic ordered_placement_strategy {
    for_each = var.launch_type == "FARGATE" ? [] : ["attribute:ecs.availability-zone"]

    content {
      type  = "spread"
      field = ordered_placement_strategy.value
    }
  }

  dynamic "network_configuration" {
    for_each = local.task_network_mode != "awsvpc" ? [] : [local.awsvpc_subnet_ids]

    content {
      subnets          = network_configuration.value
      security_groups  = local.awsvpc_security_groups
      assign_public_ip = local.awsvpc_assign_public_ip
    }
  }

  dynamic "load_balancer" {
    for_each = var.alb_target_group_name == null ? [] : [data.aws_lb_target_group.this.*.arn[0]]

    content {
      target_group_arn = load_balancer.value
      container_name   = var.alb_container_name
      container_port   = var.alb_container_port
    }
  }
}

resource "aws_ecs_task_definition" "this" {
  family = var.service_name

  execution_role_arn = var.iam_exec_role_arn

  requires_compatibilities = var.launch_type == "FARGATE" ? ["FARGATE"] : null
  cpu                      = local.task_cpu
  memory                   = local.task_memory
  network_mode             = local.task_network_mode

  container_definitions = jsonencode(var.container_definitions)
}
