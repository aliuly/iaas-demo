################################################################################
# Existing security groups
# We look these up by name so you don't have to paste IDs.
################################################################################

data "opentelekomcloud_networking_secgroup_v2" "sg_frontend" {
  name = "sg-frontend"
}

data "opentelekomcloud_networking_secgroup_v2" "sg_apps" {
  name = "sg-appsrv"
}

data "opentelekomcloud_lb_certificate_v3" "wordpress" {
  name = "wp-certificate"
}
