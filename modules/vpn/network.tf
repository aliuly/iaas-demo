locals {
  customer_eip_name = "cust-vpngw"
}

# Our Gateway
resource "opentelekomcloud_enterprise_vpn_gateway_v5" "vpngw" {
  name           = "vpngw-cass1"
  vpc_id         = var.vpc_id
  flavor         = "Basic"

  local_subnets  = var.subnets
  connect_subnet = var.dmz_id

  availability_zones = [
    "${var.region}-01",
    "${var.region}-02"
  ]

  eip1 {
    id = var.eip_1
  }
  eip2 {
    id = var.eip_2
  }
  tags = var.common_tags
}

data "external" "vpnpeer_customer_1" {
  program = [ "dns2ip", "www-${local.customer_eip_name}-1.${var.dns_zone}", "10.0.0.1" ]

}
data "external" "vpnpeer_customer_2" {
  program = [ "dns2ip", "www-${local.customer_eip_name}-2.${var.dns_zone}", "10.0.0.2" ]
}

# Customer gateways
resource "opentelekomcloud_enterprise_vpn_customer_gateway_v5" "vpn_customer_1" {
  name     = "vpnpeer-customer-1"
  id_type  = "ip"
  id_value = data.external.vpnpeer_customer_1.result["value"]
  tags = var.common_tags
}

resource "opentelekomcloud_enterprise_vpn_customer_gateway_v5" "vpn_customer_2" {
  name     = "vpnpeer-customer-2"
  id_type  = "ip"
  id_value = data.external.vpnpeer_customer_2.result["value"]
  tags = var.common_tags
}

# Connect the VPNs
resource "opentelekomcloud_enterprise_vpn_connection_v5" "vlink_customer_1" {
  name                = "tunnel-customer-1"
  gateway_id          = opentelekomcloud_enterprise_vpn_gateway_v5.vpngw.id
  gateway_ip          = opentelekomcloud_enterprise_vpn_gateway_v5.vpngw.eip1[0].id
  customer_gateway_id = opentelekomcloud_enterprise_vpn_customer_gateway_v5.vpn_customer_1.id
  peer_subnets        = var.peer_subnets
  vpn_type            = "static"
  psk                 = var.vpn_psk
  tags = var.common_tags
}
resource "opentelekomcloud_enterprise_vpn_connection_v5" "vlink_customer_2" {
  name                = "tunnel-customer-2"
  gateway_id          = opentelekomcloud_enterprise_vpn_gateway_v5.vpngw.id
  gateway_ip          = opentelekomcloud_enterprise_vpn_gateway_v5.vpngw.eip2[0].id
  customer_gateway_id = opentelekomcloud_enterprise_vpn_customer_gateway_v5.vpn_customer_2.id
  peer_subnets        = var.peer_subnets
  vpn_type            = "static"
  psk                 = var.vpn_psk
  tags = var.common_tags
}



