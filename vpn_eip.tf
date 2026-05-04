locals {
  eip_name = "uc1"
}

# Create EIP for VPN gateway
resource "opentelekomcloud_vpc_eip_v1" "eip_vpngw_1" {
  publicip {
    type = "5_bgp"
    name = "eip-${local.eip_name}-1"
  }
  bandwidth {
    name = "bw-${local.eip_name}-1"
    size = 10
    share_type = "PER"
  }
  tags = var.common_tags

  lifecycle {
    # OpenTofu will create/destroy it, but never 'update' it in place
    # ignore_changes = all
    # Prevents anyone (including Tofu) from accidentally deleting it
    prevent_destroy = true
  }
}

resource "opentelekomcloud_vpc_eip_v1" "eip_vpngw_2" {
  publicip {
    type = "5_bgp"
    name = "eip-${local.eip_name}-2"
  }
  bandwidth {
    name = "bw-${local.eip_name}-2"
    size = 10
    share_type = "PER"
  }
  tags = var.common_tags
  lifecycle {
    # OpenTofu will create/destroy it, but never 'update' it in place
    # ignore_changes = all
    # Prevents anyone (including Tofu) from accidentally deleting it
    prevent_destroy = true
  }
}

# Public DNS records
data "opentelekomcloud_dns_zone_v2" "ext_dns" {
  name = "${var.dns_zone}."
}

resource "opentelekomcloud_dns_recordset_v2" "dns_a_vpngw_1" {
  zone_id     = data.opentelekomcloud_dns_zone_v2.ext_dns.id
  name        = "www-${local.eip_name}-1.${var.dns_zone}."
  type        = "A"
  records     = [ opentelekomcloud_vpc_eip_v1.eip_vpngw_1.publicip[0].ip_address ]
  tags = var.common_tags
}

resource "opentelekomcloud_dns_recordset_v2" "dns_a_vpngw_2" {
  zone_id     = data.opentelekomcloud_dns_zone_v2.ext_dns.id
  name        = "www-${local.eip_name}-2.${var.dns_zone}."
  type        = "A"
  records     = [ opentelekomcloud_vpc_eip_v1.eip_vpngw_2.publicip[0].ip_address ]
  tags = var.common_tags
}


