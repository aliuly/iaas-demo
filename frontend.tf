#
# Configure Front Ends
#
# Unit-testing block
resource "local_file" "fe_inputs" {
  filename = "${path.module}/modules/frontend/inputs.tfvars"

  content  = <<-EOT
    region = ${jsonencode(var.region)}
    vpc_id = ${jsonencode(module.basis.vpc_id)}

    subnet_id = ${jsonencode(module.basis.sn_fe_snid)}
    network_id = ${jsonencode(module.basis.sn_fe_net)}

    dns_zone = ${jsonencode(var.dns_zone)}
    dns_name = "wp-demo1"

  EOT
  file_permission = "0644"
}

module "frontend" {
  source = "./modules/frontend"
  common_tags = var.common_tags

  region = var.region
  vpc_id = module.basis.vpc_id

  subnet_id = module.basis.sn_fe_snid
  network_id = module.basis.sn_fe_net

  dns_zone = var.dns_zone
  dns_name = "wp-demo1"

}

output "frontend" {
  value = module.frontend
}

