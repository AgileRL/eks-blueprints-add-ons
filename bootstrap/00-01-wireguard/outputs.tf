output "instance_ip" {
  description = "The public ip for ssh access"
  value       = aws_instance.wireguard.public_ip
}

output "instance_dns" {
  value = aws_instance.wireguard.public_dns
}

output "public_subnets" {
  value = tolist(data.aws_subnets.public_subnet_ids.ids)[0]
}

output "cluster_data" {
  value = data.aws_eks_cluster.this.vpc_config[0]
}
