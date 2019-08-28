# terraform module ecs-ec2

## Input Variables
- `cluster_name` - Name of ECS cluster to deploy this ECS service on
- `service_name` - Name of this ECS service
- `alb_target_group_name` - Name of ALB target group. if doesn't use ALB, set this null
- `alb_container_name` - Name of container bound to ALB target group
- `alb_container_port` - Port of container bound to ALB target group
- 'iam_exec_role_arn' - ARN of IAM role to execute this task
- `container_definitions` - Definitions of each container. (See https://docs.aws.amazon.com/ko_kr/AmazonECS/latest/developerguide/create-task-definition.html)
- `task_num` - Number of tasks to be deployed
- `deployment_min_percent` - Lower limit of tasks as a percentage
- `deployment_max_percent` - Upper limit of tasks as a percentage

## Usage
```hcl
locals {
    image_tag = "1.0"
}

data "aws_ecr_repository" "api" {
  name = "my-ecr-repo"
}

resource "aws_cloudwatch_log_group" "api" {
  name              = "/ecs/my-cluster/my-service"
  retention_in_days = 7
}

module "api" {
  source = "github.com/ridi/terraform-modules//aws/ecs-service"
  
  cluster_name = "my-cluster"
  service_name = "my-service"
        
  alb_target_group_name = "my-alb"
  alb_container_name = "app"
  alb_container_port = 80
  
  container_definitions = [
    {
      name  = "app",
      image = "${data.aws_ecr_repository.api.repository_url}:${local.image_tag}",
      portMappings = [
        { hostPort = 0, containerPort = 80 }
      ],
      environment = [
        { name = "DOCKER_IMG_DIGEST", value = data.aws_ecr_image.api.image_digest },
        { name = "DEBUG", value = "false" },
      ],
      secrets = [
        { name = "DB_HOST", valueFrom = "/rds/host" },
        { name = "DB_DBNAME", valueFrom = "/rds/db/my-service" },
        { name = "DB_USER", valueFrom = "/rds/user/someone/username" },
        { name = "DB_PASSWORD", valueFrom = "/rds/user/someone/password" },
      ],
      essential         = true
      cpu               = 100,
      memory            = 200,
      memoryReservation = 100,
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-region        = "ap-northeast-2",
          awslogs-group         = aws_cloudwatch_log_group.api.name,
          awslogs-stream-prefix = local.image_tag
        }
      },
    },
  ]
    
  task_num = 2
  deployment_min_percent = 50
  deployment_max_percent = 200
}
```
