#
# Inputs for RDS module
#
variable "flavor" {
  description = "DB flavour to use"
  type = string
  default = "rds.pg.n1.large.2.ha"    # 2 vCPU, 4GB RAM — override as needed
}

variable "vpc_id" {
  description = "VPC this DB belongs to"
  type = string
}

variable "subnet_id" {
  description = "Subnet where to place DB"
  type = string
}

variable "security_group_id" {
  description = "In what group to place db"
  type = string
}

variable "db_passwd" {
  description = "PostgreSQL root password"
  type        = string
  sensitive   = true
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
