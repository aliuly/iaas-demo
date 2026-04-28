################################################################################
## Bastion hosts
#
# Allow 22 and 443 from everywhere (Internet included)
#
resource "opentelekomcloud_networking_secgroup_v2" "sg_bastions" {
  name        = "sg-bastions"
  description = "Access to Bastion Hosts"
}

resource "opentelekomcloud_networking_secgroup_rule_v2" "r_bastions_allow_ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = opentelekomcloud_networking_secgroup_v2.sg_bastions.id
}

resource "opentelekomcloud_networking_secgroup_rule_v2" "r_bastions_allow_https" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = opentelekomcloud_networking_secgroup_v2.sg_bastions.id
}

################################################################################
# Frontend servers
#
# Allow 443 and 80.
#
resource "opentelekomcloud_networking_secgroup_v2" "sg_fe" {
  name        = "sg-frontend"
  description = "Front-end (load balancers)"
}

resource "opentelekomcloud_networking_secgroup_rule_v2" "r_fe_allow_https" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_ip_prefix  = "10.0.0.0/8"
  security_group_id = opentelekomcloud_networking_secgroup_v2.sg_fe.id
}

resource "opentelekomcloud_networking_secgroup_rule_v2" "r_fe_allow_http" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "10.0.0.0/8"
  security_group_id = opentelekomcloud_networking_secgroup_v2.sg_fe.id
}

################################################################################
# App servers
resource "opentelekomcloud_networking_secgroup_v2" "sg_apps" {
  name        = "sg-appsrv"
  description = "App Servers"
}

resource "opentelekomcloud_networking_secgroup_rule_v2" "r_apps_allow_ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_group_id   = opentelekomcloud_networking_secgroup_v2.sg_bastions.id
  security_group_id = opentelekomcloud_networking_secgroup_v2.sg_apps.id
}

resource "opentelekomcloud_networking_secgroup_rule_v2" "r_apps_allow_http" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_group_id   = opentelekomcloud_networking_secgroup_v2.sg_fe.id
  security_group_id = opentelekomcloud_networking_secgroup_v2.sg_apps.id
}

################################################################################
# Databases
resource "opentelekomcloud_networking_secgroup_v2" "sg_postgres" {
  name        = "sg-postgres"
  description = "Databases"
}

# Allow inbound PostgreSQL from internal security group only
resource "opentelekomcloud_networking_secgroup_rule_v2" "allow_postgres" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 5432
  port_range_max    = 5432
  remote_group_id   = opentelekomcloud_networking_secgroup_v2.sg_apps.id
  security_group_id = opentelekomcloud_networking_secgroup_v2.sg_postgres.id
}

resource "opentelekomcloud_networking_secgroup_rule_v2" "sfs_tcp" {
  for_each          = toset(["111", "2049", "20048"])
  direction         = "ingress" # Outbound to SFS
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = each.value
  port_range_max    = each.value
  remote_group_id   = opentelekomcloud_networking_secgroup_v2.sg_apps.id
  security_group_id = opentelekomcloud_networking_secgroup_v2.sg_postgres.id
}

resource "opentelekomcloud_networking_secgroup_rule_v2" "sfs_udp" {
  for_each          = toset(["111", "2049", "20048"])
  direction         = "ingress" # Outbound to SFS
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = each.value
  port_range_max    = each.value
  remote_group_id   = opentelekomcloud_networking_secgroup_v2.sg_apps.id
  security_group_id = opentelekomcloud_networking_secgroup_v2.sg_postgres.id
}

output "ids" {
  value = {
    sg_postgres = opentelekomcloud_networking_secgroup_v2.sg_postgres.id,
    sg_apps = opentelekomcloud_networking_secgroup_v2.sg_apps.id,
    sg_fe = opentelekomcloud_networking_secgroup_v2.sg_fe.id,
    sg_bastions = opentelekomcloud_networking_secgroup_v2.sg_bastions.id,
  }
}

output "groups" {
  value = [
    opentelekomcloud_networking_secgroup_v2.sg_postgres,
    opentelekomcloud_networking_secgroup_v2.sg_apps,
    opentelekomcloud_networking_secgroup_v2.sg_fe,
    opentelekomcloud_networking_secgroup_v2.sg_bastions,
  ]
}
