#
# BASIS
#
output "vpc_id" {
  value = module.basis.vpc_id
}

output "natgw_id" {
  value = module.basis.natgw_id
}
#
# VPN GW
#
output "dns_vpngw" {
  value = [
    opentelekomcloud_dns_recordset_v2.dns_a_vpngw_1.name,
    opentelekomcloud_dns_recordset_v2.dns_a_vpngw_2.name,
  ]
}

#
# Security groups
#
output "sg_ids" {
  value = {
    sg_postgres = opentelekomcloud_networking_secgroup_v2.sg_postgres.id,
    sg_apps = opentelekomcloud_networking_secgroup_v2.sg_apps.id,
    sg_fe = opentelekomcloud_networking_secgroup_v2.sg_fe.id,
    sg_bastions = opentelekomcloud_networking_secgroup_v2.sg_bastions.id,
  }
}

output "sg_names" {
  value = [
    opentelekomcloud_networking_secgroup_v2.sg_postgres.name,
    opentelekomcloud_networking_secgroup_v2.sg_apps.name,
    opentelekomcloud_networking_secgroup_v2.sg_fe.name,
    opentelekomcloud_networking_secgroup_v2.sg_bastions.name,
  ]
}

#
# Bastion host
#
output "bastion_int_ip" {
  value = module.bastion.bastion_int_ip
}

output "bastion_ext_ip" {
  value = module.bastion.bastion_ext_ip
}

output "bastion_int_dns" {
  value = module.bastion.bastion_int_dns
}

output "bastion_ext_dns" {
  value = module.bastion.bastion_ext_dns
}
#
# Data storage
#
output "rds" {
  value = {
    az = nonsensitive(module.datastore.postgres.availability_zone)
    private_ips = nonsensitive(module.datastore.postgres.private_ips)
    private_fqdn = nonsensitive(module.datastore.postgres.private_fqdn)
    db = [
      for d in nonsensitive(module.datastore.postgres.db): {
        port = d.port
        type = d.type
        user_name = d.user_name
        version = d.version
      }
    ]
  }
}
output "sfs" {
  value = {
    az = module.datastore.sfs.availability_zone
    share_proto = module.datastore.sfs.share_proto
    share_type = module.datastore.sfs.share_type
    export_location = module.datastore.sfs.export_location
  }
}
#
# Application servers outputs
#
output "apps" {
  value = module.apps
}
#
# Front Ends
#
output "frontend" {
  value = module.frontend
}
#
# ACME stuff
#
output "acme_common_name" {
  value = module.acme.common_name
}
output "acme_expiration" {
  value = module.acme.certificate_expires
}

output "acme_cert_id" {
  value = module.acme.cert_id
}
output "acme_cert_name" {
  value = module.acme.cert_name
}


