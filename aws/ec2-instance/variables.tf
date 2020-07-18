variable "name" {}

variable "tags" {
  description = "The tags to assign to all resources"
  type        = map(string)
  default     = {}
}

variable "create_eip" {
  description = "Whether to create EIP or not"
  type        = bool
  default     = false
}

variable "create_nat" {
  description = "Whether to set NAT configuration or not"
  type        = bool
  default     = false
}

variable "nat_ingress_cidrs" {
  description = "The list of inner subnet cidrs to be traslated by NAT (requires `create_nat`)"
  type        = list(string)
  default     = null
}

variable "nat_egress_cidr" {
  description = "The outer cidr to be translated from ingress traffic by NAT (requires `create_nat`)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "create_ssm_agent" {
  description = "Whether to set SSM session manager agent or not"
  type        = bool
  default     = false
}

variable "instance_vpc_id" {
  description = "The ID of VPC where the instance will be created"
  type        = string
}

variable "instance_subnet_id" {
  description = "The ID of subnet where the instance will be created"
  type        = string
}

variable "instance_ecs_cluster_name" {
  description = "The name of ECS cluster including this instance (ECS cluster instance only)"
  type        = string
  default     = null
}

variable "instance_name" {
  description = "The name tag attached to the instance"
  type        = string
  default     = null
}

variable "instance_ami_id" {
  description = "The id of the AMI used for creating instance"
  type        = string
}

variable "instance_timezone" {
  description = "The timezone for the instance"
  type        = string
  default     = "Asia/Seoul"
}

variable "instance_locale" {
  description = "The locale for the instance"
  type        = string
  default     = "en_US.UTF-8"
}

variable "instance_type" {
  description = "The type of the instance"
  type        = string
  default     = "t2.micro"
}

variable "instance_volume_size" {
  description = "The total size of the instance volume in gigabytes (root block size(=8GB) + EBS block size)"
  type        = number
  default     = 30
}

variable "instance_volume_type" {
  description = "The type of the instance volume"
  type        = string
  default     = "gp2"
}

variable "instance_public_key" {
  description = "The SSH public key for the the instance"
  type        = string
  default     = null
}

variable "instance_security_group_ids" {
  description = "The list of additional security groups to associate with"
  type        = list(string)
  default     = []
}

variable "instance_monitoring" {
  description = "If true, the instance will have detailed monitoring enabled"
  type        = bool
  default     = false
}

variable "instance_user_data" {
  description = "The init script for the instance"
  type        = string
  default     = null
}

variable "iam_instance_profile" {
  description = "The instance profile. (If not set, creates new one)"
  default     = null
}

variable "iam_instance_role_policy_arns" {
  description = "The list of additional instance role policys attached to newly created profile (ignored if iam_instance_profile is set)"
  type        = list(string)
  default     = []
}
