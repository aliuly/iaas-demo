output "common_name" {
  description = "The primary domain name on the certificate."
  value       = acme_certificate.this.common_name
}


output "certificate_expires" {
  description = "The expiration date of the issued certificate."
  value       = acme_certificate.this.certificate_not_after
}

output "cert_id" {
  description = "Certificate ID to attach to listeners"
  value = opentelekomcloud_lb_certificate_v3.elb_cert.id
}

output "cert_name" {
  description = "Certificate name to attach to listeners"
  value = opentelekomcloud_lb_certificate_v3.elb_cert.name
}

output "certificate_pem" {
  description = "Full certificate chain PEM (cert + issuer)"
  value     = "${acme_certificate.this.certificate_pem}${acme_certificate.this.issuer_pem}"
  sensitive = true
}

output "private_key_pem" {
  description = "Certificate private key PEM"
  value     = acme_certificate.this.private_key_pem
  sensitive = true
}
