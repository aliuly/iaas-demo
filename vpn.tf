#
# Configure VPN
#
# Unit-testing block
resource "local_file" "vpn_inputs" {
  filename = "${path.module}/modules/vpn/inputs.tfvars"

  content  = <<-EOT
    vpc_id = ${jsonencode(module.basis.vpc_id)}
    dmz_id = ${jsonencode(module.basis.sn_fe_id)}
    subnets = ${jsonencode(module.basis.subnets)}
    region = ${jsonencode(var.region)}

    eip_1 = ${jsonencode(opentelekomcloud_vpc_eip_v1.eip_vpngw_1.id)}
    eip_2 = ${jsonencode(opentelekomcloud_vpc_eip_v1.eip_vpngw_2.id)}

    vpn_psk = ${jsonencode(var.vpn_psk)}
    peer_subnets = ${jsonencode(var.peer_subnets)}
    dns_zone = ${jsonencode(var.dns_zone)}

  EOT

  file_permission = "0644"
}

module "vpn" {
  source = "./modules/vpn"
  common_tags = var.common_tags

  vpc_id = module.basis.vpc_id
  dmz_id = module.basis.sn_fe_id
  subnets = module.basis.subnets
  region = var.region

  eip_1 = opentelekomcloud_vpc_eip_v1.eip_vpngw_1.id
  eip_2 = opentelekomcloud_vpc_eip_v1.eip_vpngw_2.id

  vpn_psk = var.vpn_psk
  peer_subnets = var.peer_subnets
  dns_zone = var.dns_zone
}
