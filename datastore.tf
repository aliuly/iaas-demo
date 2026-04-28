#
# Configure RDS
#
# Unit-testing block
resource "local_file" "datatore_inputs" {
  filename = "${path.module}/modules/datastore/inputs.tfvars"

  content  = <<-EOT
    region = ${jsonencode(var.region)}

    # flavor = ${jsonencode("rds.pg.n1.large.2.ha")}
    vpc_id = ${jsonencode(module.basis.vpc_id)}
    subnet_id = ${jsonencode(module.basis.sn_db_id)}
    security_group_id = ${jsonencode(opentelekomcloud_networking_secgroup_v2.sg_postgres.id)}
    db_passwd = ${jsonencode(var.db_passwd)}

  EOT

  file_permission = "0644"
}

module "datastore" {
  source = "./modules/datastore"
  common_tags = var.common_tags
  region = var.region

  # flavor = "rds.pg.n1.large.2.ha"
  vpc_id = module.basis.vpc_id
  subnet_id = module.basis.sn_db_id
  security_group_id = opentelekomcloud_networking_secgroup_v2.sg_postgres.id
  db_passwd = var.db_passwd
}

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
  value = module.datastore.sfs
}
