locals {
  requires_compatibilities = var.launch_type == "FARGATE" ? ["FARGATE"] : []

  task_cpu          = var.task_cpu == null ? (var.launch_type == "FARGATE" ? 256 : null) : var.task_cpu
  task_memory       = var.task_memory == null ? (var.launch_type == "FARGATE" ? 512 : null) : var.task_memory
  task_network_mode = var.task_network_mode == null ? (var.launch_type == "FARGATE" ? "awsvpc" : null) : var.task_network_mode

  awsvpc_subnet_ids       = var.awsvpc_subnet_ids == null ? (local.task_network_mode == "awsvpc" ? [] : null) : var.awsvpc_subnet_ids
  awsvpc_security_groups  = var.awsvpc_security_groups == null ? (local.task_network_mode == "awsvpc" ? [] : null) : var.awsvpc_security_groups
  awsvpc_assign_public_ip = var.awsvpc_assign_public_ip == null ? (local.task_network_mode == "awsvpc" ? false : null) : var.awsvpc_assign_public_ip
}

resource "aws_ecs_service" "this" {
  name            = var.service_name
  launch_type     = var.launch_type
  cluster         = var.cluster_name
  task_definition = var.task_definition_arn == null ? aws_ecs_task_definition.this.*.arn[0] : var.task_definition_arn

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
    for_each = var.load_balancers

    content {
      target_group_arn = load_balancer.value.target_group_arn
      container_name   = load_balancer.value.container_name
      container_port   = load_balancer.value.container_port
    }
  }
}

resource "aws_ecs_task_definition" "this" {
  count = var.task_definition_arn == null ? 1 : 0

  family = var.service_name

  execution_role_arn = var.iam_exec_role_arn
  task_role_arn      = var.iam_task_role_arn

  requires_compatibilities = local.requires_compatibilities
  cpu                      = local.task_cpu
  memory                   = local.task_memory
  network_mode             = local.task_network_mode

  container_definitions = jsonencode(var.container_definitions)

  dynamic "volume" {
    for_each = var.volumes

    content {
      name      = volume.value.name
      host_path = volume.value.host_path

      dynamic "docker_volume_configuration" {
        for_each = lookup(volume.value, "docker_volume_configuration", null) == null ? [] : [volume.value.docker_volume_configuration]

        content {
          scope         = lookup(docker_volume_configuration.value, "scope", null)
          autoprovision = lookup(docker_volume_configuration.value, "autoprovision", null)
          driver        = lookup(docker_volume_configuration.value, "driver", null)
          driver_opts   = lookup(docker_volume_configuration.value, "driver_opts", null)
          labels        = lookup(docker_volume_configuration.value, "labels", null)
        }
      }
    }
  }
}

# ------------------------
# CloudWatch Metric Alarms
# ------------------------
resource "aws_cloudwatch_metric_alarm" "cpu_util" {
  count = length(var.metrix_alarm_actions) > 0 ? 1 : 0

  alarm_name        = "alarm-ecs-srv-${aws_ecs_service.this.name}-cpu-util"
  alarm_description = "The CPU utilization of ECS service '${aws_ecs_service.this.name}'"

  namespace   = "AWS/ECS"
  metric_name = "CPUUtilization"

  comparison_operator = "GreaterThanOrEqualToThreshold"
  statistic           = "Maximum"
  threshold           = var.metrix_alarm_cpu_util_threshold
  period              = var.metrix_alarm_cpu_util_period
  evaluation_periods  = 1

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = aws_ecs_service.this.name
  }

  actions_enabled = true
  alarm_actions   = var.metrix_alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "memory_util" {
  count = length(var.metrix_alarm_actions) > 0 ? 1 : 0

  alarm_name        = "alarm-ecs-srv-${aws_ecs_service.this.name}-mem-util"
  alarm_description = "The memory utilization of ECS service '${aws_ecs_service.this.name}'"

  namespace   = "AWS/ECS"
  metric_name = "MemoryUtilization"

  comparison_operator = "GreaterThanOrEqualToThreshold"
  statistic           = "Maximum"
  threshold           = var.metrix_alarm_memory_util_threshold
  period              = var.metrix_alarm_memory_util_period
  evaluation_periods  = 1

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = aws_ecs_service.this.name
  }

  actions_enabled = true
  alarm_actions   = var.metrix_alarm_actions
}
