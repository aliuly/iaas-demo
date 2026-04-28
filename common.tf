# Add a data source for the image to get its ID for the block_device block
data "opentelekomcloud_images_image_v2" "std_image" {
  name = "Standard_Ubuntu_22.04_latest"
  #~ name = "Standard_Ubuntu_24.04_amd64_bios_latest"
  #~ name = "Standard_Debian_13_amd64_bios_latest"
  #~ name = "Standard_Debian_12_amd64_bios_latest"
  most_recent = true
}
