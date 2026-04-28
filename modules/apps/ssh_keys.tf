#
# Make sure we have a ssh key available
#
resource "opentelekomcloud_compute_keypair_v2" "wordpress" {
  name       = "key-wordpress-asg"
  public_key = var.cloud_user.ssh_keys[0]
}
