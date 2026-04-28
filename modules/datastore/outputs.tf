
output "postgres" {
  value = opentelekomcloud_rds_instance_v3.postgres
  sensitive = true
}
output "sfs" {
  value = opentelekomcloud_sfs_turbo_share_v1.wordpress_sfs
}
