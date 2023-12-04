variable "cluster_name" {
  description = "The name of the cluster"
  type        = string
  default     = "agrl-core"
}

variable "vpc_subnet_name" {
  description = "The name of the public subnet to place the Wireguard server"
  type        = string
  default     = "agrl-core-public-us-east-1a"
}

# this be external
variable "vpn_server_cidr" {
  default = "172.16.16.0/20"
}

variable "wg_server_port" {
  type = number
  default = 51820
}

variable "wg_server_private_key" {
  description = "The private key of the Wireguard server"
  type = string
}

variable "wg_server_public_key" {
  description = "The public key of the Wireguard server"
  type = string
}

variable "wg_peers" {
  description = "List of Wireguard road warriors"
  type = list
}
