
# Networking: Virtual Private Cloud (VPC)
resource "opentelekomcloud_vpc_v1" "vpc" {
  name = "vpc-cass1"
  cidr = "${var.netprefix}.0.0/16"
  tags = var.common_tags
}

# Subnets
resource "opentelekomcloud_vpc_subnet_v1" "sn_admin" {
  name       = "sn-cass1-admin"
  vpc_id     = opentelekomcloud_vpc_v1.vpc.id
  cidr       = "${var.netprefix}.160.0/24"
  gateway_ip = "${var.netprefix}.160.1"
  tags = var.common_tags
}

resource "opentelekomcloud_vpc_subnet_v1" "sn_fe" {
  name       = "sn-cass3-fe"
  vpc_id     = opentelekomcloud_vpc_v1.vpc.id
  cidr       = "${var.netprefix}.43.0/24"
  gateway_ip = "${var.netprefix}.43.1"
  tags = var.common_tags
}
resource "opentelekomcloud_vpc_subnet_v1" "sn_apps" {
  name       = "sn-cass3-apps"
  vpc_id     = opentelekomcloud_vpc_v1.vpc.id
  cidr       = "${var.netprefix}.4.0/24"
  gateway_ip = "${var.netprefix}.4.1"
  tags = var.common_tags
}

resource "opentelekomcloud_vpc_subnet_v1" "sn_db" {
  name       = "sn-cass3-db"
  vpc_id     = opentelekomcloud_vpc_v1.vpc.id
  cidr       = "${var.netprefix}.3.0/24"
  gateway_ip = "${var.netprefix}.3.1"
  tags = var.common_tags
}

#
# shared NAT gateway for internet traffic
#
resource "opentelekomcloud_nat_gateway_v2" "natgw" {
  name                = "natgw-cass1"
  description         = "NAT Gateway for outbound traffic"
  spec                = "0" # "0" is Micro,"1" is Small, "2" Medium, "3" Large, "4" Extra-large
  router_id           = opentelekomcloud_vpc_v1.vpc.id
  internal_network_id = opentelekomcloud_vpc_subnet_v1.sn_fe.id # The network where the NAT GW resides
  tags = var.common_tags
}

# Create shared EIP for outbound traffic
resource "opentelekomcloud_vpc_eip_v1" "eip_outbound" {
  publicip {
    type = "5_bgp"
    name = "eip-outbound"
  }
  bandwidth {
    name = "bw-outbound"
    size = 10
    share_type = "PER"
  }
  tags = var.common_tags
}

# Outbound traffic

resource "opentelekomcloud_nat_snat_rule_v2" "subnet1_snat" {
  nat_gateway_id = opentelekomcloud_nat_gateway_v2.natgw.id
  floating_ip_id = opentelekomcloud_vpc_eip_v1.eip_outbound.id
  network_id     = opentelekomcloud_vpc_subnet_v1.sn_admin.id
}
#~ resource "opentelekomcloud_nat_snat_rule_v2" "subnet2_snat" {
  #~ nat_gateway_id = opentelekomcloud_nat_gateway_v2.natgw.id
  #~ floating_ip_id = opentelekomcloud_vpc_eip_v1.eip_outbound.id
  #~ network_id     = opentelekomcloud_vpc_subnet_v1.sn_fe.id
#~ }
resource "opentelekomcloud_nat_snat_rule_v2" "subnet3_snat" {
  nat_gateway_id = opentelekomcloud_nat_gateway_v2.natgw.id
  floating_ip_id = opentelekomcloud_vpc_eip_v1.eip_outbound.id
  network_id     = opentelekomcloud_vpc_subnet_v1.sn_apps.id
}

#~ resource "opentelekomcloud_nat_snat_rule_v2" "subnet4_snat" {
  #~ nat_gateway_id = opentelekomcloud_nat_gateway_v2.natgw.id
  #~ floating_ip_id = opentelekomcloud_vpc_eip_v1.eip_outbound.id
  #~ network_id     = opentelekomcloud_vpc_subnet_v1.sn_db.id
#~ }
