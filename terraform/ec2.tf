locals {
  project = "tsacademy-capstone"

  tags = {
    Project   = local.project
    ManagedBy = "Terraform"
  }
}

resource "random_password" "cluster_token" {
  length  = 48
  special = false
}

resource "aws_key_pair" "capstone" {
  key_name_prefix = "${local.project}-"
  public_key      = trimspace(file(pathexpand(var.ssh_public_key_path)))
  tags            = local.tags
}

resource "aws_security_group" "cluster" {
  name_prefix = "${local.project}-"
  description = "Access rules for the capstone Kubernetes nodes"
  vpc_id      = data.aws_vpc.default.id
  tags        = local.tags
}

# SSH and Kubernetes API access from your public IP.
resource "aws_vpc_security_group_ingress_rule" "admin" {
  for_each = {
    ssh = 22
    api = 6443
  }

  security_group_id = aws_security_group.cluster.id
  description       = "Admin ${each.key} access"
  cidr_ipv4         = var.admin_cidr
  ip_protocol       = "tcp"
  from_port         = each.value
  to_port           = each.value
}

# Kubernetes API and kubelet traffic between the nodes.
resource "aws_vpc_security_group_ingress_rule" "internal_tcp" {
  for_each = {
    api     = 6443
    kubelet = 10250
  }

  security_group_id            = aws_security_group.cluster.id
  referenced_security_group_id = aws_security_group.cluster.id
  description                  = "Internal ${each.key} traffic"
  ip_protocol                  = "tcp"
  from_port                    = each.value
  to_port                      = each.value
}

resource "aws_vpc_security_group_ingress_rule" "flannel" {
  security_group_id            = aws_security_group.cluster.id
  referenced_security_group_id = aws_security_group.cluster.id
  description                  = "Internal pod networking"
  ip_protocol                  = "udp"
  from_port                    = 8472
  to_port                      = 8472
}

resource "aws_vpc_security_group_egress_rule" "outbound" {
  security_group_id = aws_security_group.cluster.id
  description       = "Outbound downloads and cluster traffic"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_instance" "control_plane" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  associate_public_ip_address = true
  key_name                    = aws_key_pair.capstone.key_name
  vpc_security_group_ids      = [aws_security_group.cluster.id]

  user_data = templatefile("${path.module}/templates/server.sh.tftpl", {
    cluster_token = random_password.cluster_token.result
    k3s_version   = var.k3s_version
  })

  user_data_replace_on_change = true

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  lifecycle {
    precondition {
      condition     = contains(data.aws_subnets.default.ids, var.subnet_id)
      error_message = "Choose a default subnet in the default VPC."
    }
  }

  depends_on = [
    aws_vpc_security_group_ingress_rule.admin,
    aws_vpc_security_group_ingress_rule.internal_tcp,
    aws_vpc_security_group_ingress_rule.flannel,
    aws_vpc_security_group_egress_rule.outbound
  ]

  tags = merge(local.tags, {
    Name = "${local.project}-control-plane"
  })
}

resource "aws_instance" "worker" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  associate_public_ip_address = true
  key_name                    = aws_key_pair.capstone.key_name
  vpc_security_group_ids      = [aws_security_group.cluster.id]

  user_data = templatefile("${path.module}/templates/agent.sh.tftpl", {
    cluster_token     = random_password.cluster_token.result
    k3s_version       = var.k3s_version
    server_private_ip = aws_instance.control_plane.private_ip
  })

  user_data_replace_on_change = true

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  lifecycle {
    replace_triggered_by = [aws_instance.control_plane.id]
  }

  tags = merge(local.tags, {
    Name = "${local.project}-worker"
  })
}
