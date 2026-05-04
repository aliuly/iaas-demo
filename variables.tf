variable "common_tags" {
  description = "Common tags for environment"
  type = map(string)
  default = {
    environment = "development"
    managed_by = "OpenTofu"
    CASIO = "Use1"
  }
}
variable "region" {
  type = string
}

# For basis configuration
variable "netprefix" {
  description = "Network prefix to use for CIDR (VPCs are assumed to be Class-C's)"
  default = "10.9"
  type = string
}

# For VPN configuration
variable "vpn_psk" {
  description = "Used to secure VPN links"
  type = string
  sensitive = true
}

variable "peer_subnets" {
  type = list(string)
  description = "Networks on the far end of the VPN"
}

variable "dns_zone" {
  description = "DNS zone to use"
  type = string
}

# Default login

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

# Users that can login to bastion host
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

# RDS PostgreSQL
variable "db_passwd" {
  description = "PostgreSQL root password"
  type        = string
  sensitive   = true
}


variable "wp_rds_passwd" {
  type = string
  sensitive = true
  description = "WordPres RDS user password"
}

# ── WordPress ────────────────────────────────────────────────
variable "wp_domain" {
  description = "Public domain / hostname for WordPress (used in wp-config and Authentik redirect)"
  type        = string
}

variable "wp_admin_passwd" {
  description = "WordPress admin password"
  type        = string
  sensitive   = true
}

variable "wp_admin_email" {
  description = "WordPress admin e-mail"
  type        = string
}

# ── Authentik SSO ─────────────────────────────────────────────
variable "authentik_base_url" {
  description = "Base URL of your Authentik instance (e.g. https://auth.example.com)"
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

# ----- TLS Certificates -----
variable "acme_otc_creds" {
  description = "Used to configure the OTC ACME provider"
  type = object({
    OTC_USER_NAME    = string
    OTC_PASSWORD     = string
    OTC_DOMAIN_NAME  = string
    OTC_PROJECT_NAME = string
  })
}
variable "le_email" {
  description = "E-Mail address to send to Let's Encrypt"
  type = string
}

