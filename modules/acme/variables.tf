variable "common_tags" {
  description = "Common tags for environment"
  type = map(string)
  default = {
    environment = "development"
    managed_by = "OpenTofu"
    CASIO = "Use1"
  }
}

variable "domains" {
  description = "domains to configure"
  type = list(string)
}

variable "le_email" {
  description = "E-Mail address to send to Let's Encrypt"
  type = string
}

variable "acme_otc_creds" {
  description = "Used to configure the OTC ACME provider"
  type = object({
    OTC_USER_NAME    = string
    OTC_PASSWORD     = string
    OTC_DOMAIN_NAME  = string
    OTC_PROJECT_NAME = string
  })
}

