#
# Configure AppServers
#
locals {
  user_data = replace(templatefile("${path.module}/wp.yaml", {
      user = var.cloud_user.name
      passwd = var.cloud_user.passwd
      ssh_keys = var.cloud_user.ssh_keys
      region = var.region
      dns_zone = var.dns_zone
      installer = base64gzip(file("${path.module}/wp-init.sh"))
      db_inst =  base64gzip(file("${path.module}/wp-db-init.sh"))
      db_drop =  base64gzip(file("${path.module}/wp-db-drop.sh"))

      wp_config = {
        # SFS/NFS
        SFS_EXPORT      = var.sfs_nfs_export
        SFS_MOUNT       = var.sfs_mount_point
        # Where WordPress stores uploads, object-cache, etc. on the shared FS
        WP_SHARED_DIR   = "${var.sfs_mount_point}/${var.wordpress_data_dir}"
        WP_UPLOADS_DIR  = "${var.sfs_mount_point}/${var.wordpress_data_dir}/uploads"
        WP_INSTALL_LOCK = "${var.sfs_mount_point}/${var.wordpress_data_dir}/.installed"

        # Database
        DB_HOST         = var.rds_host
        DB_PORT         = var.rds_port
        DB_NAME         = var.rds_db_name
        DB_USER         = var.rds_username
        DB_PASSWORD     = var.rds_password
        DB_ADM_PASSWD   = var.rds_admin_passwd
        DB_PREFIX       = var.wordpress_table_prefix

        # WordPress
        WP_DOMAIN       = var.wordpress_domain
        WP_ADMIN_USER   = var.wordpress_admin
        WP_ADMIN_PASS   = var.wordpress_admin_password
        WP_ADMIN_EMAIL  = var.wordpress_admin_email

        AUTHENTIK_BASE_URL = var.authentik_base_url
        AUTHENTIK_CLIENT_ID = var.authentik_client_id
        AUTHENTIK_CLIENT_SECRET = var.authentik_client_secret

        WP_ROOT         = "/var/www/html/wordpress"
      }
    }), "\r", "")
}

#~ #
#~ # Useful for testing the contents of user data templates
#~ #
#~ resource "local_file" "_user_data" {
  #~ filename = "${path.module}/user_data.tmp"
  #~ content = local.user_data
  #~ file_permission = "0644"
#~ }

resource "opentelekomcloud_compute_instance_v2" "ecs_appsrv1" {
  name = "appsrv1"
  flavor_name     = "s2.medium.1"
  security_groups = var.security_groups
  network {
    uuid = var.subnet_id
  }

  # 1. System Disk (Bootable)
  block_device {
    uuid                  = var.stdimg_id
    source_type           = "image"
    destination_type      = "volume"
    boot_index            = 0
    volume_size           = 32   # System Disk: 32 GB
    delete_on_termination = true
  }

  # Cloud-init configuration
  user_data = local.user_data
  tags = var.common_tags
}

# Private DNS records
data "opentelekomcloud_dns_zone_v2" "dns" {
  name = var.dns_zone
}
resource "opentelekomcloud_dns_recordset_v2" "dnsint_a_appsrv1" {
  zone_id     = data.opentelekomcloud_dns_zone_v2.dns.id
  name        = "${opentelekomcloud_compute_instance_v2.ecs_appsrv1.name}.${var.dns_zone}."
  type        = "A"
  records     = [ opentelekomcloud_compute_instance_v2.ecs_appsrv1.access_ip_v4 ]
  tags = var.common_tags
}

# Attach it to Load Balancer
resource "opentelekomcloud_lb_member_v3" "pet" {
  pool_id       = var.lbaas_pool_id
  address       = opentelekomcloud_compute_instance_v2.ecs_appsrv1.access_ip_v4
  protocol_port = var.backend_port
  subnet_id     = var.subnet_snid
  weight        = 1
}
