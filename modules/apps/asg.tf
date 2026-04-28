#
# Configure AppServers via Auto Scaling
#
# Converted from a single opentelekomcloud_compute_instance_v2 to an AS
# configuration + two AZ-pinned groups sharing a single ELB backend pool.
#
# Everything in the locals block (user_data, wp.yaml template, all variables)
# is unchanged — AS passes user_data to each instance it launches exactly
# as the ECS resource did.
#

################################################################################
# AS Launch Configuration
#
# Replaces the opentelekomcloud_compute_instance_v2 block.
# Maps each argument directly from the original ECS resource:
#
#   flavor_name       → instance_config.flavor
#   block_device      → instance_config.disk
#   user_data         → instance_config.user_data (base64-encoded)
#   security_groups   → instance_config.security_groups
#   network.uuid      → AS group networks block (see below)
################################################################################

resource "opentelekomcloud_as_configuration_v1" "wordpress" {
  scaling_configuration_name = "wordpress-as-config"

  instance_config {
    # Same flavor as the original ECS instance
    flavor = "s2.medium.1"

    # Same image as the original ECS instance
    image = var.stdimg_id

    # SSH key pair for emergency access — add a key_pair variable if needed
    key_name = opentelekomcloud_compute_keypair_v2.wordpress.name

    # user_data must be base64-encoded for AS configurations
    user_data = base64encode(local.user_data)

    # Mirrors the block_device in the original ECS resource
    disk {
      size        = 32
      volume_type = "SAS"
      disk_type   = "SYS"   # system / boot disk
    }

    # Security groups — same list passed via var.security_groups_ids
    security_groups = var.security_groups_ids
  }
}

################################################################################
# AS Group — AZ1
#
# The network/subnet placement comes from the AS group, not the configuration.
# Both AZ groups use the same subnet (OTC subnets are not AZ-scoped);
# AZ pinning is done via available_zones.
################################################################################

resource "opentelekomcloud_as_group_v1" "az1" {
  scaling_group_name       = "wordpress-asg-az1"
  scaling_configuration_id = opentelekomcloud_as_configuration_v1.wordpress.id

  vpc_id = var.vpc_id

  networks {
    id = var.subnet_id
  }

  # Security groups at the group level (mirrors original ECS security_groups)
  dynamic "security_groups" {
    for_each = var.security_groups_ids
    content {
      id = security_groups.value
    }
  }

  # Pin to AZ1 only
  available_zones = [var.az1_name]

  # Register instances into the shared ELB backend pool
  lbaas_listeners {
    pool_id       = var.lbaas_pool_id
    protocol_port = var.backend_port
    weight        = var.az1_weight
  }

  # Manual scaling — min == desired means OTC holds exactly this count.
  # Change az1_instances + tofu apply to scale up or down.
  min_instance_number    = var.az1_instances
  max_instance_number    = var.asg_max_instance_count
  desire_instance_number = var.az1_instances

  # Use ELB health check results to detect and replace failed instances
  health_periodic_audit_method = "ELB_AUDIT"
  health_periodic_audit_time   = 5

  instance_terminate_policy = "OLD_CONFIG_OLD_INSTANCE"
  delete_publicip           = true
  delete_instances          = "yes"

  tags = var.common_tags
}

################################################################################
# AS Group — AZ2
################################################################################

resource "opentelekomcloud_as_group_v1" "az2" {
  scaling_group_name       = "wordpress-asg-az2"
  scaling_configuration_id = opentelekomcloud_as_configuration_v1.wordpress.id

  vpc_id = var.vpc_id

  networks {
    id = var.subnet_id
  }

  dynamic "security_groups" {
    for_each = var.security_groups_ids
    content {
      id = security_groups.value
    }
  }

  # Pin to AZ2 only
  available_zones = [var.az2_name]

  lbaas_listeners {
    pool_id       = var.lbaas_pool_id
    protocol_port = var.backend_port
    weight        = var.az2_weight
  }

  min_instance_number    = var.az2_instances
  max_instance_number    = var.asg_max_instance_count
  desire_instance_number = var.az2_instances

  health_periodic_audit_method = "ELB_AUDIT"
  health_periodic_audit_time   = 5

  instance_terminate_policy = "OLD_CONFIG_OLD_INSTANCE"
  delete_publicip           = true
  delete_instances          = "yes"

  tags = var.common_tags
}

################################################################################
# DNS
#
# The original code created an A record per instance using its fixed IP.
# With AS, instance IPs are dynamic and unknown at plan time, so instead
# we point DNS at the ELB VIP — which is stable and never changes.
#
# Replace var.elb_vip_address with the output from your ELB stack:
#   elb_vip_address = module.elb.elb_vip_address   (if same stack)
#   elb_vip_address = var.elb_vip_address           (if separate stack, shown below)
################################################################################

#~ data "opentelekomcloud_dns_zone_v2" "dns" {
  #~ name = var.dns_zone
#~ }

#~ resource "opentelekomcloud_dns_recordset_v2" "wordpress" {
  #~ zone_id = data.opentelekomcloud_dns_zone_v2.dns.id
  #~ name    = "wordpress.${var.dns_zone}."
  #~ type    = "A"
  #~ ttl     = 300
  #~ records = [var.elb_vip_address]
  #~ tags    = var.common_tags
#~ }
