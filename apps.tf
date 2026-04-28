#
# Configure Application servers
#

# Unit-testing block
resource "local_file" "apps_inputs" {
  filename = "${path.module}/modules/apps/inputs.tfvars"

  content  = <<-EOT
    security_groups = ${jsonencode([opentelekomcloud_networking_secgroup_v2.sg_apps.name])}
    security_groups_ids = ${jsonencode([opentelekomcloud_networking_secgroup_v2.sg_apps.id])}

    vpc_id = ${jsonencode(module.basis.vpc_id)}
    subnet_id = ${jsonencode(module.basis.sn_apps_id)}
    subnet_snid = ${jsonencode(module.basis.sn_apps_snid)}
    stdimg_id = ${jsonencode(data.opentelekomcloud_images_image_v2.std_image.id)}

    cloud_user = ${jsonencode(var.cloud_user)}

    region = ${jsonencode(var.region)}
    dns_zone = ${jsonencode(var.dns_zone)}

    sfs_nfs_export = ${jsonencode(module.datastore.sfs.export_location)}

    rds_host = ${jsonencode(module.datastore.postgres.private_fqdn)}
    rds_password = ${jsonencode(var.wp_rds_passwd)}
    rds_admin_passwd = ${jsonencode(var.db_passwd)}

    wordpress_admin_email = ${jsonencode(var.wp_admin_email)}
    wordpress_domain = ${jsonencode(var.wp_domain)}
    wordpress_admin_password = ${jsonencode(var.wp_admin_passwd)}

    authentik_base_url = ${jsonencode(var.authentik_base_url)}
    authentik_client_id = ${jsonencode(var.authentik_client_id)}
    authentik_client_secret = ${jsonencode(var.authentik_client_secret)}

    lbaas_pool_id = ${jsonencode(module.frontend.backend_pool_id)}

  EOT

  file_permission = "0644"
}


module "apps" {
  source = "./modules/apps"
  common_tags = var.common_tags

  security_groups = [opentelekomcloud_networking_secgroup_v2.sg_apps.name]
  security_groups_ids = [opentelekomcloud_networking_secgroup_v2.sg_apps.id]

  vpc_id = module.basis.vpc_id
  subnet_id = module.basis.sn_apps_id
  subnet_snid = module.basis.sn_apps_snid
  stdimg_id = data.opentelekomcloud_images_image_v2.std_image.id

  cloud_user = var.cloud_user

  region = var.region
  dns_zone = var.dns_zone

  sfs_nfs_export = module.datastore.sfs.export_location

  rds_host = module.datastore.postgres.private_fqdn
  rds_password = var.wp_rds_passwd
  rds_admin_passwd = var.db_passwd

  wordpress_admin_email = var.wp_admin_email
  wordpress_domain = var.wp_domain
  wordpress_admin_password = var.wp_admin_passwd

  authentik_base_url = var.authentik_base_url
  authentik_client_id = var.authentik_client_id
  authentik_client_secret = var.authentik_client_secret

  lbaas_pool_id = module.frontend.backend_pool_id

}

output "apps" {
  value = module.apps
}
