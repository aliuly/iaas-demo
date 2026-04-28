
# ---------------------------------------------------------------------------
# ELBv3 Server Certificate
#
# lifecycle.ignore_changes on certificate/private_key means that if the cert
# files are updated on disk (e.g. by a cron-driven renewal) and you re-run
# tofu apply, the existing OTC certificate object is LEFT UNTOUCHED.
#
# To intentionally replace the certificate (e.g. after a manual renewal that
# you want to push), run:
#   tofu apply -replace=opentelekomcloud_lb_certificate_v3.elb_cert
# ---------------------------------------------------------------------------
resource "opentelekomcloud_lb_certificate_v3" "elb_cert" {
  name        = "wp-certificate"
  description = "Certificate used for the demo"

  # ELB shared load balancers require type = "server"
  type = "server"

  certificate = file("${path.module}/snakeoil/ssl-cert-snakeoil.pem")
  private_key = file("${path.module}/snakeoil/ssl-cert-snakeoil.key")

  lifecycle {
    # Prevent OpenTofu from overwriting the certificate when the local files
    # change (e.g. after an automated renewal via cron).
    ignore_changes = [
      certificate,
      private_key,
    ]
    # Prevent accidental deletion of a certificate that may be in active use.
    prevent_destroy = true
  }
}
