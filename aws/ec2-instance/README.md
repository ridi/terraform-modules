# ec2-instance

## Usage
```hcl
module "instance" {
  source = "github.com/ridi/terraform-modules//aws/ec2-instance"

  name   = "my-instance"

  # For NAT instance
  create_nat        = true
  nat_ingress_cidrs = ["10.1.0.0/16", "10.2.0.0/16"]
  nat_egress_cidr   = "0.0.0.0/0"

  # For installing SSM agent
  create_ssm_agent = true

  # For ECS Cluster instance
  instance_ecs_cluster_name = "my-ecs-cluster"

  instance_type   = "t3.nano"
  instance_ami_id = "ami-01622871b8eb5d0e5"

  instance_vpc_id    = "vpc-1234abcd"
  instance_subnet_id = "subnet-1234abcd"

  instance_security_group_ids = ["sg-1234abcd"]
}
```

## Input Variables

### Common
- `name`:
- `tags`: The tags to assign to all resources

### VPC
- `create_eip`: Whether to create EIP or not

### EC2 instance
- `create_nat`: Whether to set NAT configuration or not
- `nat_ingress_cidrs`: The list of inner subnet cidrs to be traslated by NAT (requires `create_nat`) 
- `nat_egress_cidr`: The outer cidr to be translated from ingress traffic by NAT (requires `create_nat`)
- `create_ssm_agent`: Whether to set SSM session manager agent or not
- `instance_vpc_id`: The ID of VPC where the instance will be created
- `instance_subnet_id`: The ID of subnet where the instance will be created
- `instance_ecs_cluster_name`: The name of ECS cluster including this instance (ECS cluster instance only)
- `instance_name`: The name tag attached to the instance
- `instance_ami_id`: The id of the AMI used for creating instance
- `instance_timezone`: The timezone for the instance
- `instance_locale`: The locale for the instance
- `instance_type`: The type of the instance
- `instance_volume_size`: The total size of the instance volume in gigabytes (root block size(=8GB) + EBS block size)
- `instance_public_key`: The SSH public key for the instance
- `instance_security_group_ids`: The list of additional security groups to associate with
- `instance_monitoring`: If true, the instance will have detailed monitoring enabled
- `instance_user_data`: The init script for instance

### IAM
- `iam_instance_profile`: The instance profile. (If not set, creates new one)
- `iam_instance_role_policy_arns`: The list of additional instance role policys attached to newly created profile (ignored if `iam_instance_profile` is set)

## Output Variables
- `network_interface_id`: The network interface id of this instance
- `public_ip`: The public ip of this instance
