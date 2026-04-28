
variable "vpc_id" {
  description = "VPC this VPN belongs to"
  type = string
}
variable "dmz_id" {
  description = "Subnet where we position the VPN"
  type = string
}

variable "subnets" {
  description = "Networks that can use this VPN"
  type = list(string)
}

variable "peer_subnets" {
  type = list(string)
  description = "Networks on the far end of the VPN"
}

variable "region" {
  description = "Region hosting us"
  type = string
}

variable "vpn_psk" {
  description = "PSK to secure VPN"
  type = string
  sensitive = true
}

variable "common_tags" {
  description = "Common tags for environment"
  type = map(string)
  default = {
    environment = "development"
    managed_by = "OpenTofu"
    CASIO = "Use1"
  }
}

variable "eip_1" {
  description = "EIP for VPN gateway"
  type = string
}

variable "eip_2" {
  description = "EIP for VPN gateway"
  type = string
}


variable "dns_zone" {
  description = "DNS zone to use"
  type = string
}


