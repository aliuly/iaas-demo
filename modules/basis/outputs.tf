output "vpc_id" {
  value = opentelekomcloud_vpc_v1.vpc.id
}

output "sn_admin_id" {
  value = opentelekomcloud_vpc_subnet_v1.sn_admin.id
}

output "sn_admin_net" {
  value = opentelekomcloud_vpc_subnet_v1.sn_admin.network_id
}

output "sn_admin_snid" {
  value = opentelekomcloud_vpc_subnet_v1.sn_admin.subnet_id
}


output "sn_fe_id" {
  value = opentelekomcloud_vpc_subnet_v1.sn_fe.id
}

output "sn_fe_net" {
  value = opentelekomcloud_vpc_subnet_v1.sn_fe.network_id
}

output "sn_fe_snid" {
  value = opentelekomcloud_vpc_subnet_v1.sn_fe.subnet_id
}

output "sn_apps_id" {
  value = opentelekomcloud_vpc_subnet_v1.sn_apps.id
}

output "sn_apps_net" {
  value = opentelekomcloud_vpc_subnet_v1.sn_apps.network_id
}

output "sn_apps_snid" {
  value = opentelekomcloud_vpc_subnet_v1.sn_apps.subnet_id
}

output "sn_db_id" {
  value = opentelekomcloud_vpc_subnet_v1.sn_db.id
}

output "sn_db_net" {
  value = opentelekomcloud_vpc_subnet_v1.sn_db.network_id
}

output "sn_db_snid" {
  value = opentelekomcloud_vpc_subnet_v1.sn_db.subnet_id
}

output "subnets" {
  value = [
    opentelekomcloud_vpc_subnet_v1.sn_admin.cidr,
    opentelekomcloud_vpc_subnet_v1.sn_fe.cidr,
    opentelekomcloud_vpc_subnet_v1.sn_apps.cidr,
    opentelekomcloud_vpc_subnet_v1.sn_db.cidr,
  ]
}

output "natgw_id" {
  value = opentelekomcloud_nat_gateway_v2.natgw.id
}
