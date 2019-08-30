# ecs-autoscailing-cluster

## Usage
```hcl
data "aws_subnet_ids" "private" {
  vpc_id = "vpc-0123abcd"
  
  tags = {
    Private = true
  }
}

data "aws_subnet" "private" {
  count = length(data.aws_subnet_ids.private.ids)
  id    = data.aws_subnet_ids.private.ids.* [count.index]
}

data "aws_ami" "ecs" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-2.0.*"]
  }
}

# ----------
# Security Group
# ----------
module "sg_my_service" {
  source = "terraform-aws-modules/security-group/aws"

  vpc_id = "vpc-0123abcd"
  name = "my-service"
  description = "The security group for instances in ECS cluster 'my-service'"

  ingress_rules = ["all-tcp"]
  ingress_cidr_blocks = data.aws_subnet.private.*.cidr_block

  egress_rules = ["all-tcp"]
  egress_cidr_blocks = ["0.0.0.0/0"]
}

# ----------
# ECS Cluster
# ----------
module "cluster_my_service" {
  source = "github.com/ridi/terraform-modules//aws/ecs-autoscailing-cluster"

  ecs_cluster_name = "my-service"

  asg_subnet_ids           = data.aws_subnet_ids.private.ids
  asg_availability_zones   = data.aws_subnet.private.*.availability_zone
  asg_min_size             = 0
  asg_max_size             = 4
  asg_desired_capacity     = 2

  ec2_type   = "t3.micro"
  ec2_ami_id = data.aws_ami.ecs.image_id

  ec2_security_group_ids = [
    module.sg_my_service.this_security_group_id,
  ]
}
```

## Input Variables

### Common
- `create`: Whether to create this resources or not
- `tags`: The tags to assign to all resources

### ECS Cluster
- `ecs_cluster_name`: The name of ECS cluster

### EC2 Autoscaling Group
- `asg_availability_zones`: The availability zones where autoscale group instances are created
- `asg_subnet_ids`: The list of subnet IDs associate with autoscale instances
- `asg_min_size`: The minimum number of autoscale instances.
- `asg_max_size`: The maximum number of autoscale instances.
- `asg_desired_capacity`: The decired number of autoscale instances.
- `asg_termination_policies`: The policies that choose which instance to terminate first

### EC2 Launch Configuration
- `ec2_name`: The name tag attached to scaled instance
- `ec2_ami_id`: The id of the AMI used for the autoscale instances
- `ec2_timezone`: The timezone for the autocale instances
- `ec2_locale`: The locale for the autocale instances
- `ec2_type`: The autoscale instance type
- `ec2_volume_size`: The total size of the autoscale instance volume in gigabytes (root block size(=8GB) + EBS block size)
- `ec2_public_key`: The SSH public key for the autoscale instances
- `ec2_security_group_ids`: The list of security group ids to associate with autoscale instances
- `ec2_role_policy_arns`: The list of additional instance role policy arn
- `ec2_enable_monitoring`: If true, autoscale instance will have detailed monitoring enabled
- `ec2_user_data`: The init script for EC2

### CloudWatch
- `metrix_alarm_actions`: The actions of CloudWatch metrix alarm
- `metrix_alarm_memory_util_threshold`: The threshold of memory utilization CloudWatch metrix alarm
- `metrix_alarm_memory_util_period`: The period of memory utilization CloudWatch metrix alarm
- `metrix_alarm_cpu_util_threshold`: The threshold of CPU utilization CloudWatch metrix alarm
- `metrix_alarm_cpu_util_period`: The period of CPU utilization CloudWatch metrix alarm
- `task_stopped_event_target_arn`: The arn of task stopped event target
