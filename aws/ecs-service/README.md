# ecs-service

## Usage
```hcl
module "service" {
  source = "github.com/ridi/terraform-modules//aws/ecs-service"
  
  cluster_name = "my-cluster"
  service_name = "my-service"
        
  alb_target_group_name = "my-alb"
  alb_container_name    = "app"
  alb_container_port    = 80
  
  # If you runs with EC2 type instead Fargate, ignore belows (launch_type, awsvpc_*).
  launch_type            = "FARGATE"
  awsvpc_subnet_ids      = data.aws_subnet_ids.private.ids
  awsvpc_security_groups = ["sg-1234abcd"]
  
  container_definitions = [
    {
      name  = "app",
      image = "my-repo/my-image:1.0",
      portMappings = [
        { containerPort = 80 }
      ],
      environment = [
        { name = "FOO", value = "This is FOO" },
        { name = "BAR", value = "This is BAR" },
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
          awslogs-group         = "/ecs/my-cluster/my-service"
          awslogs-stream-prefix = "1.0"
        }
      },
    },
  ]
    
  task_num = 2
  deployment_min_percent = 50
  deployment_max_percent = 200
}
```

## Input Variables

### ECS Cluster
- `cluster_name` - The name of ECS cluster to deploy ECS service on

### ECS Service
- `service_name` - The name of this ECS service
- `launch_type` - The launch type on which to run your service. ('EC2' or 'FARGATE')
- `task_definition_arn` - The arn of task definition. If not set, creates new one. (container_definitions is required)
- `task_num` - The number of tasks to be deployed
- `deployment_min_percent` - The lower limit of tasks as a percentage
- `deployment_max_percent` - The upper limit of tasks as a percentage
- `awsvpc_subnet_ids` - The subnets associated with the task or service (task_network_mode)
- `awsvpc_security_groups` - The security groups associated with the task or service
- `awsvpc_assign_public_ip` - Whether assigns a public IP address to the ENI or not
- `alb_target_group_name` - The name of ALB target group. if doesn't use ALB, set this null
- `alb_container_name` - The name of container bound to ALB target group
- `alb_container_port` - The port of container bound to ALB target group

### ECS Task Definition
These variables are ignored if `task_definition_arn` is set
- `task_cpu` - The number of cpu units used by the task. (used in Fargate)
- `task_memory` - The amount (in MB) of memory used by the task. (used in Fargate)
- `task_network_mode` - The Docker networking mode to use for the containers in the task. ('none', 'bridge', 'awsvpc', 'host')
- `iam_task_role_arn` - The ARN of IAM role of ECS task
- `iam_exec_role_arn` - ARN of IAM role to execute ECS task
- `container_definitions` - The definitions of each container. (See https://docs.aws.amazon.com/ko_kr/AmazonECS/latest/developerguide/create-task-definition.html)
