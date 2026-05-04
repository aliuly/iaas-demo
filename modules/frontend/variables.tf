variable "common_tags" {
  description = "Common tags for environment"
  type = map(string)
  default = {
    environment = "development"
    managed_by = "OpenTofu"
    CASIO = "Use1"
  }
}


################################################################################
# General
################################################################################

variable "region" {
  description = "OTC region (e.g. eu-de)"
  type        = string
  default     = "eu-de"
}

################################################################################
# Networking
################################################################################

variable "vpc_id" {
  description = "VPC ID where the load balancer will be created"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID (OTC 'subnet_id', the neutron subnet UUID)"
  type        = string
}

variable "network_id" {
  description = "Network ID (OTC 'network_id', the neutron network UUID)"
  type        = string
}

################################################################################
# ELB
################################################################################

variable "elb_name" {
  description = "Name prefix for the ELB and its child resources"
  type        = string
  default     = "wp-elb"
}

variable "tls_cert_id" {
  description = "LB TLS Certificate Id"
  type = string
}

#~ variable "l4_flavor" {
  #~ description = "ELBv3 L4 flavor ID. Use the data source below to discover available flavors."
  #~ type        = string
  #~ default     = "L4_flavor.elb.s1.small" # smallest shared L4
#~ }

#~ variable "l7_flavor" {
  #~ description = "ELBv3 L7 flavor ID"
  #~ type        = string
  #~ default     = "L7_flavor.elb.s1.small" # smallest shared L7
#~ }

################################################################################
# Backend (WordPress)
################################################################################

variable "backend_port" {
  description = "Port on which WordPress backends listen (usually 80)"
  type        = number
  default     = 80
}

#~ variable "backend_instances" {
  #~ description = "Map of backend instance name → private IP address"
  #~ type        = map(string)
  #~ # Example:
  #~ # {
  #~ #   "wp-01" = "10.0.1.10"
  #~ #   "wp-02" = "10.0.1.11"
  #~ # }
#~ }

variable "dns_zone" {
  description = "DNS zone to use"
  type = string
}

variable "dns_name" {
  description = "DNS name to use"
  type = string
}
