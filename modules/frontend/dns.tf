# Public DNS records
data "opentelekomcloud_dns_zone_v2" "extdns" {
  name = "${var.dns_zone}."
}

# Private DNS records
resource "opentelekomcloud_dns_recordset_v2" "dnsint_a_name" {
  zone_id     = data.opentelekomcloud_dns_zone_v2.extdns.id
  name        = "${var.dns_name}.${var.dns_zone}."
  type        = "A"
  records     = [ opentelekomcloud_lb_loadbalancer_v3.wordpress.vip_address ]
  tags = var.common_tags
}
