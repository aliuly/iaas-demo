#
# Initialize the infrastructure
#
module "basis" {
  source = "./modules/basis"
  common_tags = var.common_tags
  netprefix = var.netprefix
}

# ---------------------------------------------------------------------------
# ACME — configure TLS certificates
# ---------------------------------------------------------------------------
module "acme" {
  source = "./modules/acme"
  domains = [
    "wp-demo1.cassiopeia.public.t-cloud.com",
  ]
  acme_otc_creds = var.acme_otc_creds
  le_email = var.le_email
}

# ---------------------------------------------------------------------------
# Bastion — Admin access to the environment
# ---------------------------------------------------------------------------
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
# ---------------------------------------------------------------------------
# Configure VPN
# ---------------------------------------------------------------------------
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
# ---------------------------------------------------------------------------
# Data store
# ---------------------------------------------------------------------------

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
# ---------------------------------------------------------------------------
# App Server tier
# ---------------------------------------------------------------------------
#
# Configure Application servers
#

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

# ---------------------------------------------------------------------------
# Configure Front Ends
# ---------------------------------------------------------------------------

module "frontend" {
  source = "./modules/frontend"
  common_tags = var.common_tags

  region = var.region
  vpc_id = module.basis.vpc_id

  subnet_id = module.basis.sn_fe_snid
  network_id = module.basis.sn_fe_net

  dns_zone = var.dns_zone
  dns_name = "wp-demo1"

  # TLS configuration
  tls_cert_id = module.acme.cert_id
}

