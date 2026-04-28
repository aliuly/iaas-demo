# Provider configuration
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    opentelekomcloud = {
      source  = "opentelekomcloud/opentelekomcloud"
      version = ">= 1.36.0"
    }
  }
  # Comment-out if not using remote state...
  backend "s3" {}
}

# Bare provider configurations
provider "opentelekomcloud" {}
