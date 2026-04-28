#
# Inputs for Desktop module
#
variable "security_groups" {
  description = "In what groups to place systems"
  type = list(string)
}

variable "subnet_id" {
  description = "Subnet where to place systems"
  type = string
}

variable "natgw_id" {
  description = "NATGW we use for inbound traffic"
  type = string
}

variable "stdimg_id" {
  description = "Standard OS image to use"
  type = string
}

variable "cloud_user" {
  description = "Credentials for a generic cloud user"
  type = object({
    name = optional(string, "clouduser")
    passwd = string
    ssh_keys = optional(list(string), [])
  })
  sensitive = true
  default = { passwd = "x" }
}

variable "local_users" {
  description = "Small set of users to create"
  sensitive = true
  type = list(object({
    name = string
    gecos = optional(string,"")
    passwd = string
    ssh_keys = optional(list(string),[])
  }))
  default = []
}

variable "dns_zone" {
  description = "DNS zone to use"
  type = string
}

variable "region" {
  description = "Region hosting us"
  type = string
}

#
# Generics
#
variable "common_tags" {
  description = "Common tags for environment"
  type = map(string)
  default = {
    environment = "development"
    managed_by = "OpenTofu"
    CASIO = "Use1"
  }
}
