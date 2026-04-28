#
# Initialize the infrastructure
#
module "basis" {
  source = "./modules/basis"
  common_tags = var.common_tags
  netprefix = var.netprefix
}

output "basis" {
  value = module.basis
}
