# ------------------------
# Network Interface (+EIP)
# ------------------------
locals {
  instance_name   = (var.instance_name == null ? "Instance ${var.name}" : var.instance_name)
  key_name        = "key-${var.name}"
  role_name       = "role-ec2-${var.name}"
  policy_ssm_name = "policy-ssm-${var.name}"
  sg_nat_name     = "${var.name}-nat"

  security_groups = var.create_nat == true ? concat(
    var.instance_security_group_ids,
    [module.sg_nat.this_security_group_id]
  ) : var.instance_security_group_ids
}

resource "aws_network_interface" "this" {
  description = "For instance ${local.instance_name}"

  subnet_id         = var.instance_subnet_id
  source_dest_check = false
  security_groups   = local.security_groups
  tags              = var.tags
}

resource "aws_eip" "this" {
  count = var.create_eip ? 1 : 0

  vpc  = true
  tags = var.tags
}

resource "aws_eip_association" "this" {
  count = var.create_eip ? 1 : 0

  allocation_id        = aws_eip.this.*.id[0]
  network_interface_id = aws_network_interface.this.*.id[0]
}

# ------------------------
# EC2 instance
# ------------------------
resource "aws_key_pair" "this" {
  count      = var.instance_public_key == null ? 0 : 1
  key_name   = local.key_name
  public_key = var.instance_public_key
}

resource "aws_instance" "this" {
  instance_type        = var.instance_type
  ami                  = var.instance_ami_id
  key_name             = var.instance_public_key == null ? null : aws_key_pair.this.*.key_name[0]
  user_data_base64     = data.template_cloudinit_config.this.rendered
  iam_instance_profile = var.iam_instance_profile == null ? aws_iam_instance_profile.this.*.name[0] : var.iam_instance_profile

  monitoring = var.instance_monitoring

  root_block_device {
    volume_size           = var.instance_volume_size
    volume_type           = var.instance_volume_type
    delete_on_termination = true
  }

  network_interface {
    device_index          = 0
    delete_on_termination = false
    network_interface_id  = aws_network_interface.this.*.id[0]
  }

  tags = merge(var.tags, {
    Name = local.instance_name
  })
}

data "template_cloudinit_config" "this" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"

    content = templatefile("${path.module}/include/cloud.cfg.tpl", {
      locale           = var.instance_locale
      timezone         = var.instance_timezone
      ecs_cluster_name = var.instance_ecs_cluster_name
      create_ssm_agent = var.create_ssm_agent
      create_nat       = var.create_nat
      nat_src_cidrs    = var.nat_ingress_cidrs
      nat_dst_cidr     = var.nat_egress_cidr
    })
  }

  dynamic "part" {
    for_each = var.instance_user_data == null ? [] : [var.instance_user_data]

    content {
      content_type = "text/x-shellscript"
      content      = part.value
    }
  }
}

# ------------------------
# Security Group
# ------------------------

# NAT <--all---- var.private_subnet_cidr_blocks
# NAT ---all---> anywhere
module "sg_nat" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "3.10.0"

  create = var.create_nat

  description = "The NAT access for instance ${local.instance_name}"

  vpc_id          = var.instance_vpc_id
  name            = local.sg_nat_name
  use_name_prefix = true

  ingress_rules       = ["all-all"]
  ingress_cidr_blocks = var.nat_ingress_cidrs

  egress_rules       = ["all-all"]
  egress_cidr_blocks = [var.nat_egress_cidr]

  tags = var.tags
}

# ------------------------------------------------------------
# IAM instance profile
# ------------------------------------------------------------
resource "aws_iam_instance_profile" "this" {
  count = var.iam_instance_profile == null ? 1 : 0

  name = aws_iam_role.this.*.name[0]
  role = aws_iam_role.this.*.name[0]
}

resource "aws_iam_role" "this" {
  count = var.iam_instance_profile == null ? 1 : 0

  description = "For instance ${local.instance_name}"

  name = local.role_name

  assume_role_policy = jsonencode({
    Version = "2008-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# ------------------------
# IAM Policies: SSM session manager
# ------------------------
resource "aws_iam_policy" "ssm" {
  count = var.iam_instance_profile == null && var.create_ssm_agent == true ? 1 : 0

  name = local.policy_ssm_name
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

resource "aws_iam_role_policy_attachment" "ssm" {
  count = var.iam_instance_profile == null && var.create_ssm_agent == true ? 1 : 0

  role       = aws_iam_role.this.*.name[0]
  policy_arn = aws_iam_policy.ssm.*.arn[0]
}

resource "aws_iam_role_policy_attachment" "ecs" {
  count = var.instance_ecs_cluster_name == null ? 0 : 1

  role       = aws_iam_role.this.*.name[0]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}


# ------------------------
# IAM Policies: etc
# ------------------------
resource "aws_iam_role_policy_attachment" "etc" {
  count = var.iam_instance_profile == null ? length(var.iam_instance_role_policy_arns) : 0

  role       = aws_iam_role.this.*.name[0]
  policy_arn = var.iam_instance_role_policy_arns[count.index]
}
