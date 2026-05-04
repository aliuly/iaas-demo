terraform {
  required_providers {
    opentelekomcloud = {
      source = "opentelekomcloud/opentelekomcloud"
    }
    # ACME Provider for Let's Encrypt
    acme = {
      source  = "vancluever/acme"
    }
    # TLS Provider (often needed for creating private keys)
    tls = {
      source  = "hashicorp/tls"
    }
  }
}
