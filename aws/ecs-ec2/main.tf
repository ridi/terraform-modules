data "aws_lb_target_group" "this" {
  count = var.alb_target_group_name == null ? 0 : 1
  name  = var.alb_target_group_name
}

resource "aws_ecs_service" "this" {
  name            = var.service_name
  launch_type     = "EC2"
  cluster         = var.cluster_name
  task_definition = aws_ecs_task_definition.this.arn

  desired_count                      = var.task_num
  deployment_minimum_healthy_percent = var.deployment_min_percent
  deployment_maximum_percent         = var.deployment_max_percent

  ordered_placement_strategy {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
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

  container_definitions = jsonencode(var.container_definitions)
}
