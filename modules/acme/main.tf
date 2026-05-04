#
# Request TLS certificates
#
# 2. Create a Private Key for your Let's Encrypt Account
resource "tls_private_key" "reg_private_key" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256" # P256 is the standard "sweet spot" for performance and security
}

# 3. Register your Account with Let's Encrypt
resource "acme_registration" "reg" {
  account_key_pem = tls_private_key.reg_private_key.private_key_pem
  email_address   = var.le_email
}

# 4. Request the Certificate using DNS Challenge (OTC DNS)
resource "acme_certificate" "this" {
  account_key_pem           = acme_registration.reg.account_key_pem
  common_name               = "${var.domains[0]}"
  subject_alternative_names = length(var.domains) > 1 ? slice(var.domains, 1, length(var.domains)) : null

  dns_challenge {
    provider = "otc" # Uses OTC DNS to verify ownership
    config = var.acme_otc_creds
  }
}

# 5. Upload the Certificate to OTC ELB
resource "opentelekomcloud_lb_certificate_v3" "elb_cert" {
  name        = "letsencrypt-cert-demo1"
  description = "Managed by OpenTofu - Let's Encrypt"
  type        = "server"

  # ACME provides the cert and the chain separately or concatenated.
  # For OTC, we send the cert + the issuer (chain) in the 'content' field.
  certificate     = "${acme_certificate.this.certificate_pem}${acme_certificate.this.issuer_pem}"
  private_key = acme_certificate.this.private_key_pem
}
