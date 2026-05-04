#
# Cloud Init for app servers
#
locals {
  user_data = replace(templatefile("${path.module}/wp.yaml", {
      user = var.cloud_user.name
      passwd = var.cloud_user.passwd
      ssh_keys = var.cloud_user.ssh_keys
      region = var.region
      dns_zone = var.dns_zone
      installer = base64gzip(file("${path.module}/wp-init.sh"))
      plugin_installer = base64gzip(file("${path.module}/wp-plugins.sh"))
      hardening =  base64gzip(file("${path.module}/hardening.sh"))
      db_inst =  base64gzip(file("${path.module}/wp-db-init.sh"))
      db_drop =  base64gzip(file("${path.module}/wp-db-drop.sh"))
      openidc_json = base64gzip(templatefile("${path.module}/jsdata/daggerhart-openid-connect-generic.json",{
        authentik_base_url = trim(var.authentik_base_url,"/"),
        authentik_app_slug = var.authentik_app_slug,
        authentik_client_id = var.authentik_client_id,
        authentik_client_secret = var.authentik_client_secret,
      }))
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

        WP_ROOT         = "/var/www/html/wordpress"
      }
    }), "\r", "")
}

#
# Useful for testing the contents of user data templates
#
#~ resource "local_file" "_user_data1" {
  #~ filename = "${path.module}/user_data.tmp"
  #~ content = local.user_data
  #~ file_permission = "0644"
#~ }
#~ resource "local_file" "_user_data2" {
  #~ filename = "${path.module}/tmpu.josn"
  #~ content = templatefile("${path.module}/jsdata/daggerhart-openid-connect-generic.json",{
        #~ authentik_base_url = trim(var.authentik_base_url,"/"),
        #~ authentik_app_slug = var.authentik_app_slug,
        #~ authentik_client_id = var.authentik_client_id,
        #~ authentik_client_secret = var.authentik_client_secret,
      #~ })
  #~ file_permission = "0644"
#~ }
