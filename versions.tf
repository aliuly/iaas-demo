# Provider configuration
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    opentelekomcloud = {
      source  = "opentelekomcloud/opentelekomcloud"
      version = ">= 1.36.0"
    }
    # ACME Provider for Let's Encrypt
    acme = {
      source  = "vancluever/acme"
      version = "~> 2.48.0"
    }
    # TLS Provider (often needed for creating private keys)
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
  # Comment-out if not using remote state...
  backend "s3" {}
}

provider "opentelekomcloud" {}
# ACME Provider Configuration
provider "acme" {
  # Production server
  # server_url = "https://acme-v02.api.letsencrypt.org/directory"
  # Staging server
  server_url = "https://acme-staging-v02.api.letsencrypt.org/directory"
}
