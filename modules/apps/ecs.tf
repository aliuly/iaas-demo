#
# Configure AppServers
#

resource "opentelekomcloud_compute_instance_v2" "ecs_appsrv1" {
  name = "appsrv1"
  flavor_name     = "s2.medium.1"
  security_groups = var.security_groups
  network {
    uuid = var.subnet_id
  }

  # 1. System Disk (Bootable)
  block_device {
    uuid                  = var.stdimg_id
    source_type           = "image"
    destination_type      = "volume"
    boot_index            = 0
    volume_size           = 32   # System Disk: 32 GB
    delete_on_termination = true
  }

  # Cloud-init configuration
  user_data = local.user_data
  tags = var.common_tags
}

# Private DNS records
data "opentelekomcloud_dns_zone_v2" "dns" {
  name = var.dns_zone
}
resource "opentelekomcloud_dns_recordset_v2" "dnsint_a_appsrv1" {
  zone_id     = data.opentelekomcloud_dns_zone_v2.dns.id
  name        = "${opentelekomcloud_compute_instance_v2.ecs_appsrv1.name}.${var.dns_zone}."
  type        = "A"
  records     = [ opentelekomcloud_compute_instance_v2.ecs_appsrv1.access_ip_v4 ]
  tags = var.common_tags
}

# Attach it to Load Balancer
resource "opentelekomcloud_lb_member_v3" "pet" {
  pool_id       = var.lbaas_pool_id
  address       = opentelekomcloud_compute_instance_v2.ecs_appsrv1.access_ip_v4
  protocol_port = var.backend_port
  subnet_id     = var.subnet_snid
  weight        = 1
}
