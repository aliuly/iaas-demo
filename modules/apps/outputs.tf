
################################################################################
# Auto Scaling
################################################################################

output "as_config_id" {
  description = "ID of the shared AS launch configuration"
  value       = opentelekomcloud_as_configuration_v1.wordpress.id
}

output "as_group_az1_id" {
  description = "ID of the AZ1 Auto Scaling group"
  value       = opentelekomcloud_as_group_v1.az1.id
}

output "as_group_az2_id" {
  description = "ID of the AZ2 Auto Scaling group"
  value       = opentelekomcloud_as_group_v1.az2.id
}

################################################################################
# Operational summary — printed after every apply
# Quick reference for the current state without digging through the console.
################################################################################

output "summary" {
  description = "Key operational values at a glance"
  value = {
    wordpress_url     = "https://${var.wordpress_domain}"
    tls_policy        = "TLS-1-2-FS-WITH-1-3"
    az1 = {
      az       = var.az1_name
      instances = var.az1_instances
      weight   = var.az1_weight
      active   = var.az1_weight > 0 && var.az1_instances > 0
    }
    az2 = {
      az       = var.az2_name
      instances = var.az2_instances
      weight   = var.az2_weight
      active   = var.az2_weight > 0 && var.az2_instances > 0
    }
  }
}
