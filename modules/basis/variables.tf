
#~ variable "cloud_user" {
  #~ description = "Credentials for a generic cloud user"
  #~ type = object({
    #~ name = optional(string, "clouduser")
    #~ passwd = string
    #~ ssh_keys = optional(list(string), [])
  #~ })
  #~ sensitive = true
  #~ default = { passwd = "x" }
#~ }

variable "common_tags" {
  description = "Common tags for environment"
  type = map(string)
  default = {
    environment = "development"
    managed_by = "OpenTofu"
    CASIO = "Use1"
  }
}

variable "netprefix" {
  description = "Network prefix to use for CIDR (VPCs are assumed to be Class-C's)"
  default = "10.212"
  type = string
}
