#
# Configure bastion hosts
#
# Unit-testing block
#

resource "local_file" "bastion_inputs" {
  filename = "${path.module}/modules/bastion/inputs.tfvars"

  content  = <<-EOT
    security_groups = ${jsonencode([opentelekomcloud_networking_secgroup_v2.sg_bastions.name])}
    subnet_id = ${jsonencode(module.basis.sn_admin_id)}
    natgw_id = ${jsonencode(module.basis.natgw_id)}
    stdimg_id = ${jsonencode(data.opentelekomcloud_images_image_v2.std_image.id)}
    cloud_user = ${jsonencode(var.cloud_user)}
    local_users = ${jsonencode(var.local_users)}
    region = ${jsonencode(var.region)}
    dns_zone = ${jsonencode(var.dns_zone)}
  EOT

  file_permission = "0644"
}

module "bastion" {
  source = "./modules/bastion"
  common_tags = var.common_tags

  security_groups = [opentelekomcloud_networking_secgroup_v2.sg_bastions.name]
  subnet_id = module.basis.sn_admin_id
  natgw_id = module.basis.natgw_id
  stdimg_id = data.opentelekomcloud_images_image_v2.std_image.id
  cloud_user = var.cloud_user
  local_users = var.local_users
  region = var.region
  dns_zone = var.dns_zone

}

output "bastion" {
  value = module.bastion
}
