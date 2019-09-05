locals {
  asg_name        = "asg-${var.ecs_cluster_name}"
  lc_name         = "lc-${var.ecs_cluster_name}"
  iam_role_name   = "role-ec2-${var.ecs_cluster_name}"
  ssm_policy_name = "policy-ssm-${var.ecs_cluster_name}"
}

resource "aws_ecs_cluster" "cluster" {
  name = var.ecs_cluster_name
}

# ------------------------
# EC2 Autoscale Group
# ------------------------
resource "aws_autoscaling_group" "asg" {
  name_prefix = "${local.asg_name}-"

  vpc_zone_identifier = var.asg_subnet_ids
  availability_zones  = var.asg_availability_zones

  min_size             = var.asg_min_size
  max_size             = var.asg_max_size
  desired_capacity     = var.asg_desired_capacity
  termination_policies = var.asg_termination_policies

  launch_configuration = aws_launch_configuration.instance.name

  tags = concat(
    [for key, value in var.tags :
      {
        key                 = key
        value               = value
        propagate_at_launch = true
      }
    ],
    [
      {
        key                 = "Name"
        value               = var.instance_name != null ? var.instance_name : format("[autoscaled] %s", aws_ecs_cluster.cluster.name),
        propagate_at_launch = true
      },
    ]
  )

  lifecycle {
    create_before_destroy = true
  }
}

# ------------------------
# EC2 Launch Configuration
# ------------------------
resource "aws_launch_configuration" "instance" {
  name_prefix = "${local.lc_name}-"

  image_id             = var.instance_ami_id
  instance_type        = var.instance_type
  enable_monitoring    = var.instance_enable_monitoring
  security_groups      = var.instance_security_group_ids
  iam_instance_profile = aws_iam_instance_profile.instance.*.name[0]

  user_data_base64 = data.template_cloudinit_config.instance.rendered

  lifecycle {
    create_before_destroy = true
  }
}

data "template_cloudinit_config" "instance" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"

    content = <<EOF
#cloud-config
# vim: syntax=yaml
locale: ${var.instance_locale}
timezone: ${var.instance_timezone}

package_upgrade: true
packages:
  - https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm

write_files:
  - path: /etc/environment
    content: |
      LC_ALL=en_US.UTF-8
  - path: /etc/ecs/ecs.config
    content: |
      ECS_CLUSTER=${aws_ecs_cluster.cluster.name}
EOF
  }

  part {
    content_type = "text/x-shellscript"
    content      = var.instance_user_data == null ? "" : var.instance_user_data
  }
}

# ------------------------
# IAM Role for EC2
# ------------------------
resource "aws_iam_instance_profile" "instance" {
  count = var.iam_instance_profile == null ? 1 : 0

  name = aws_iam_role.instance.*.name[0]
  role = aws_iam_role.instance.*.name[0]
}

resource "aws_iam_role" "instance" {
  count = var.iam_instance_profile == null ? 1 : 0

  name        = local.iam_role_name
  description = "Role for instances of ASG ${local.asg_name}"

  assume_role_policy = jsonencode({
    Version = "2008-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = ["ec2.amazonaws.com"]
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "instance_ecs" {
  count = var.iam_instance_profile == null ? 1 : 0

  role       = aws_iam_role.instance.*.name[0]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# ------------------------
# IAM Policy for SSM session manager
# ------------------------
resource "aws_iam_policy" "instance_session" {
  count = var.iam_instance_profile == null ? 1 : 0

  name = local.ssm_policy_name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:UpdateInstanceInformation",
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel",
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "instance_session" {
  count = var.iam_instance_profile == null ? 1 : 0

  role       = aws_iam_role.instance.*.name[0]
  policy_arn = aws_iam_policy.instance_session.*.arn[0]
}

resource "aws_iam_role_policy_attachment" "instance_additional" {
  count = var.iam_instance_profile == null ? length(var.iam_instance_role_policy_arns) : 0

  role       = aws_iam_role.instance.*.name[0]
  policy_arn = var.iam_instance_role_policy_arns[count.index]
}

# ------------------------
# CloudWatch Metric Alarms
# ------------------------
resource "aws_cloudwatch_metric_alarm" "cpu_util" {
  count = length(var.metrix_alarm_actions) > 0 ? 1 : 0

  alarm_name        = "alarm-${aws_ecs_cluster.cluster.name}-cpu-util"
  alarm_description = "The CPU utilization of ECS cluster '${aws_ecs_cluster.cluster.name}'"

  namespace   = "AWS/ECS"
  metric_name = "CPUUtilization"

  comparison_operator = "GreaterThanOrEqualToThreshold"
  statistic           = "Maximum"
  threshold           = var.metrix_alarm_cpu_util_threshold
  period              = var.metrix_alarm_cpu_util_period
  evaluation_periods  = 1

  dimensions = {
    ClusterName = aws_ecs_cluster.cluster.name
  }

  actions_enabled = true
  alarm_actions   = var.metrix_alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "memory_util" {
  count = length(var.metrix_alarm_actions) > 0 ? 1 : 0

  alarm_name        = "alarm-${aws_ecs_cluster.cluster.name}-memory-util"
  alarm_description = "The memory utilization of ECS cluster '${aws_ecs_cluster.cluster.name}'"

  namespace   = "AWS/ECS"
  metric_name = "MemoryUtilization"

  comparison_operator = "GreaterThanOrEqualToThreshold"
  statistic           = "Maximum"
  threshold           = var.metrix_alarm_memory_util_threshold
  period              = var.metrix_alarm_memory_util_period
  evaluation_periods  = 1

  dimensions = {
    ClusterName = aws_ecs_cluster.cluster.name
  }

  actions_enabled = true
  alarm_actions   = var.metrix_alarm_actions
}

# ------------------------
# Cloudwatch Events
# ------------------------
resource "aws_cloudwatch_event_rule" "task_stopped" {
  count = var.task_stopped_event_target_arn == null ? 0 : 1

  name        = "event-${aws_ecs_cluster.cluster.name}-task-stopped"
  description = "A ECS task stopped in ECS cluster '${aws_ecs_cluster.cluster.name}'"

  event_pattern = jsonencode({
    source = [
      "aws.ecs",
    ]
    detail-type = [
      "ECS Task State Change",
    ]
    detail = {
      clusterArn = [
        aws_ecs_cluster.cluster.arn,
      ]
      lastStatus = [
        "STOPPED",
      ]
      stoppedReason = [
        "Essential container in task exited",
      ]
    }
  })
}

resource "aws_cloudwatch_event_target" "task_stopped" {
  count = var.task_stopped_event_target_arn == null ? 0 : 1

  rule = aws_cloudwatch_event_rule.task_stopped.*.name[0]
  arn  = var.task_stopped_event_target_arn

  input_transformer {
    input_template = <<EOF
{
  "event": "${aws_cloudwatch_event_rule.task_stopped.*.name[0]}",
  "resource": <task_arn>,
  "status": <detail_type>,
  "reason": <stopped_reason>,
  "description": "${aws_cloudwatch_event_rule.task_stopped.*.description[0]}",
  "time": <time>
}
EOF

    input_paths = {
      detail_type    = "$.detail-type"
      task_arn       = "$.detail.taskArn"
      stopped_reason = "$.detail.stoppedReason"
      time           = "$.time"
    }
  }
}

