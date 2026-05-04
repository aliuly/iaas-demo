locals {
  vm_name = "bastion1"
  user_data = replace(templatefile("${path.module}/bastion.yaml", {
      user = var.cloud_user.name
      passwd = var.cloud_user.passwd
      ssh_keys = var.cloud_user.ssh_keys
      more_users = var.local_users
      region = var.region
      dns_zone = var.dns_zone
      hardening = base64gzip(file("${path.module}/hardening.sh"))
    }), "\r", "")
}

resource "opentelekomcloud_compute_instance_v2" "ecs_bastion1" {
  name            = local.vm_name
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

#~ resource "local_file" "bastion_user_data" {
  #~ filename = "${path.module}/user_data.tmp"
  #~ content = local.user_data
  #~ file_permission = "0644"
#~ }


# Create EIP for Bastion host
resource "opentelekomcloud_vpc_eip_v1" "eip_bastion1" {
  publicip {
    type = "5_bgp"
    name = "eip-bastion1"
  }
  bandwidth {
    name = "bw-bastion1"
    size = 10
    share_type = "PER"
  }
  tags = var.common_tags
}

# Add DNAT mappings
resource "opentelekomcloud_nat_dnat_rule_v2" "natfw_bastion1_22" {
  nat_gateway_id        = var.natgw_id
  floating_ip_id        = opentelekomcloud_vpc_eip_v1.eip_bastion1.id
  protocol              = "tcp"
  internal_service_port = 22
  external_service_port = 22
  port_id               = opentelekomcloud_compute_instance_v2.ecs_bastion1.network[0].port
}

resource "opentelekomcloud_nat_dnat_rule_v2" "natfw_bastion1_443" {
  nat_gateway_id        = var.natgw_id
  floating_ip_id        = opentelekomcloud_vpc_eip_v1.eip_bastion1.id
  protocol              = "tcp"
  internal_service_port = 443
  external_service_port = 443
  port_id               = opentelekomcloud_compute_instance_v2.ecs_bastion1.network[0].port
}

# Public DNS records
data "opentelekomcloud_dns_zone_v2" "extdns" {
  name = "${var.dns_zone}."
}
resource "opentelekomcloud_dns_recordset_v2" "dnsext_a_bastion1" {
  zone_id     = data.opentelekomcloud_dns_zone_v2.extdns.id
  name        = "www-${local.vm_name}.${var.dns_zone}."
  type        = "A"
  records     = [ opentelekomcloud_vpc_eip_v1.eip_bastion1.publicip[0].ip_address ]
  tags = var.common_tags
}

# Private DNS records
resource "opentelekomcloud_dns_recordset_v2" "dnsint_a_bastion1" {
  zone_id     = data.opentelekomcloud_dns_zone_v2.extdns.id
  name        = "${local.vm_name}.${var.dns_zone}."
  type        = "A"
  records     = [ opentelekomcloud_compute_instance_v2.ecs_bastion1.access_ip_v4 ]
  tags = var.common_tags
}
