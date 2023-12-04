data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

locals {
  vpc_id = data.aws_eks_cluster.this.vpc_config[0].vpc_id
}

# # Lookup the "Public" subnet in which our WireGuard instance should be placed
data "aws_subnets" "public_subnet_ids" {
  filter {
    name = "tag:Name"
    values = [var.vpc_subnet_name]
  }
}

# Lookup the AMI instance that corresponds to a Ubuntu server
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  owners = ["099720109477"] # Canonical

  tags = {
    GithubRepo = "github.com/AgileRL/terraform-aws-eks-blueprints"
  }
}

# Create a security group that allows access to the EC2 instance
resource "aws_security_group" "wireguard" {
  name = "${var.cluster_name}-vpn"
  description = "Communication to and from VPC endpoint"
  vpc_id = data.aws_eks_cluster.this.vpc_config[0].vpc_id
  ingress {
    description = "Wireguard from anywhere"
    from_port = var.wg_server_port
    to_port = var.wg_server_port
    protocol = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # normally there should be direct ssh access
  # ingress {
  #   description = "ssh from anywhere"
  #   from_port = 22
  #   to_port = 22
  #   protocol = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-vpn"
  }
}

# resource "aws_security_group" "road_warrior" {
#   name = "${var.cluster_name}-wg-rw-web"
#   description = "WG road warrior to node HTTP/HTTPS service"
#   vpc_id = data.aws_eks_cluster.this.vpc_config[0].vpc_id
#   ingress {
#     description = "WG road warrior to node HTTP"
#     from_port = 80
#     to_port = 80
#     protocol = "tcp"
#     security_groups = [aws_security_group.wireguard.id] 
#   }

#   ingress {
#     description = "WG road warrior to node HTTPS"
#     from_port = 443
#     to_port = 443
#     protocol = "tcp"
#     security_groups = [aws_security_group.wireguard.id] 
#   }

#   ingress {
#     description = "WG road warrior to ping node"
#     from_port = 0
#     to_port = 0
#     protocol = "icmp"
#     security_groups = [aws_security_group.wireguard.id] 
#   }

#   egress {
#     from_port = 0
#     to_port = 0
#     protocol = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "${var.cluster_name}-wg-to-web"
#   }
# }

data "aws_security_group" "cluster_node" {
  filter {
    name = "tag:Name"
    values = ["${var.cluster_name}-node"]
  }
  
}

# FIXME
#     description = "WG road warrior to node HTTPS"
resource "aws_security_group_rule" "wg_rw_node_icmp" {
  description = "WG road warrior to ping node"
  type              = "ingress"
  from_port         = -1
  to_port           = -1
  protocol          = "icmp"

  security_group_id = data.aws_security_group.cluster_node.id
  source_security_group_id = aws_security_group.wireguard.id 
}

data "local_file" "wg_ssh_pub_key" {
    filename = "${path.module}/${var.cluster_name}-wg-key-pair.pub"
}

# ssh key for instance 
resource "aws_key_pair" "wg_ssh_key" {
  key_name   = "${var.cluster_name}-wg-ssh-key"
  public_key = data.local_file.wg_ssh_pub_key.content
}

# Provision the actual EC2 instance based on the AMI selected above
resource "aws_instance" "wireguard" {
  ami = data.aws_ami.ubuntu.id
  instance_type = "t3a.nano"
  subnet_id = tolist(data.aws_subnets.public_subnet_ids.ids)[0]
  vpc_security_group_ids = [aws_security_group.wireguard.id]
  user_data = data.template_file.wireguard_userdata.rendered

  key_name   = "${var.cluster_name}-wg-ssh-key"
}

# Reserve a persistent IP address and associate the IP address
# with the EC2 instance
resource "aws_eip" "wireguard" {
  domain = "vpc"
}
resource "aws_eip_association" "wireguard" {
  instance_id = aws_instance.wireguard.id
  allocation_id = aws_eip.wireguard.id
}


data "template_file" "wireguard_userdata_peers" {
  template = file("resources/wireguard-user-data-peers.tpl")
  count = length(var.wg_peers)
  vars = {
    peer_name = var.wg_peers[count.index].name
    peer_public_key = var.wg_peers[count.index].public_key
    peer_allowed_ips = var.wg_peers[count.index].allowed_ips
  }
}

data "template_file" "wireguard_userdata" {
  template = file("resources/wireguard-user-data.tpl")
  vars = {
    client_network_cidr = var.vpn_server_cidr
    wg_server_private_key = var.wg_server_private_key
    wg_server_public_key = var.wg_server_public_key
    wg_server_port = var.wg_server_port
    wg_peers = join("\n", data.template_file.wireguard_userdata_peers.*.rendered)
  }
}

