output "bastion_id" {
  value = opentelekomcloud_compute_instance_v2.ecs_bastion1.id
}
output "bastion_int_ip" {
  value = opentelekomcloud_compute_instance_v2.ecs_bastion1.access_ip_v4
}

output "bastion_ext_ip" {
  value = opentelekomcloud_vpc_eip_v1.eip_bastion1.publicip[0].ip_address
}

output "bastion_int_dns" {
  value = "${local.vm_name}.${var.dns_zone}"
}

output "bastion_ext_dns" {
  value = "www-${local.vm_name}.${var.dns_zone}"
}
