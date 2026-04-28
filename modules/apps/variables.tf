#
# Inputs for App Servers module — AS version
#
# All original variables are preserved unchanged.
# New variables added at the bottom for AS/ELB integration.
#

variable "security_groups" {
  description = "Security group names to attach to instances"
  type        = list(string)
}

variable "subnet_id" {
  description = "Subnet where instances are placed"
  type        = string
}

variable "subnet_snid" {
  description = "NeutronID where instances are placed (neutron network ID for AS groups)"
  type        = string
}


variable "stdimg_id" {
  description = "Standard OS image to use"
  type        = string
}

variable "cloud_user" {
  description = "Credentials for a generic cloud user"
  type = object({
    name     = optional(string, "clouduser")
    passwd   = string
    ssh_keys = optional(list(string), [])
  })
  sensitive = true
  default   = { passwd = "x" }
}

variable "dns_zone" {
  description = "DNS domain name"
  type        = string
}

variable "region" {
  description = "Region hosting us"
  type        = string
}

# ── SFS Turbo ──────────────────────────────────────────────────────────────
variable "sfs_nfs_export" {
  description = "SFS NFS export address (for mounting)"
  type        = string
}

variable "sfs_mount_point" {
  description = "Local mount point for SFS Turbo share"
  type        = string
  default     = "/mnt/sfs"
}

variable "wordpress_data_dir" {
  description = "Sub-directory under sfs_mount_point used for WP uploads / shared data"
  type        = string
  default     = "wordpress"
}

# ── RDS ────────────────────────────────────────────────────────────────────
variable "rds_host" {
  description = "RDS PostgreSQL private endpoint hostname / IP"
  type        = string
}

variable "rds_port" {
  description = "RDS PostgreSQL port"
  type        = number
  default     = 5432
}

variable "rds_db_name" {
  description = "WordPress database name"
  type        = string
  default     = "wordpress"
}

variable "rds_username" {
  description = "RDS master / app username"
  type        = string
  default     = "wordpress"
}

variable "rds_password" {
  description = "RDS password"
  type        = string
  sensitive   = true
}

variable "rds_admin_passwd" {
  description = "RDS superuser password"
  type        = string
  sensitive   = true
}

# ── WordPress ──────────────────────────────────────────────────────────────
variable "wordpress_domain" {
  description = "Public domain / hostname for WordPress"
  type        = string
}

variable "wordpress_admin" {
  description = "WordPress admin username"
  type        = string
  default     = "wpadmin"
}

variable "wordpress_admin_password" {
  description = "WordPress admin password"
  type        = string
  sensitive   = true
}

variable "wordpress_admin_email" {
  description = "WordPress admin e-mail"
  type        = string
}

variable "wordpress_table_prefix" {
  description = "WordPress DB table prefix"
  type        = string
  default     = "wp_"
}

# ── Authentik SSO ──────────────────────────────────────────────────────────
variable "authentik_base_url" {
  description = "Base URL of your Authentik instance"
  type        = string
}

variable "authentik_client_id" {
  description = "OAuth2 Client ID registered in Authentik for WordPress"
  type        = string
}

variable "authentik_client_secret" {
  description = "OAuth2 Client Secret from Authentik"
  type        = string
  sensitive   = true
}

# ── Common ─────────────────────────────────────────────────────────────────
variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    environment = "development"
    managed_by  = "OpenTofu"
    CASIO       = "Use1"
  }
}

variable "vpc_id" {
  description = "VPC ID for the AS groups"
  type        = string
}

variable "asg_max_instance_count" {
  description = "Hard ceiling on instances per AZ group (safety limit)"
  type        = number
  default     = 6
}

# ── New: ELB integration ───────────────────────────────────────────────────

variable "lbaas_pool_id" {
  description = "ELB backend pool ID — from the ELB stack's backend_pool_id output"
  type        = string
}

variable "backend_port" {
  description = "Port WordPress listens on — from the ELB stack's backend_port output"
  type        = number
  default     = 80
}

# ── New: AZ placement and traffic control ─────────────────────────────────

variable "az1_name" {
  description = "Availability zone for the first AS group (e.g. eu-de-01)"
  type        = string
  default     = "eu-de-01"
}

variable "az1_instances" {
  description = "Number of instances to run in AZ1. Set to 0 for standby."
  type        = number
  default     = 1
}

variable "az1_weight" {
  description = "ELB traffic weight for AZ1 instances. Set to 0 to drain traffic."
  type        = number
  default     = 1
}

variable "az2_name" {
  description = "Availability zone for the second AS group (e.g. eu-de-02)"
  type        = string
  default     = "eu-de-02"
}

variable "az2_instances" {
  description = "Number of instances to run in AZ2. Set to 0 for standby."
  type        = number
  default     = 1
}

variable "az2_weight" {
  description = "ELB traffic weight for AZ2 instances. Set to 0 to drain traffic."
  type        = number
  default     = 1
}

variable "security_groups_ids" {
  description = "Security group IDs to attach to instances"
  type        = list(string)
}

