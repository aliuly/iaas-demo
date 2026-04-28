################################################################################
# Dedicated Elastic Load Balancer (ELBv3)
#
# • Internal-only (no public_ip block → no EIP attached)
# • Placed in the application subnet inside the VPC
# • Uses sg-frontend security group
################################################################################

resource "opentelekomcloud_lb_loadbalancer_v3" "wordpress" {
  name               = var.elb_name
  description        = "Internal ELB for WordPress – HTTPS termination"
  router_id          = var.vpc_id
  network_ids        = [var.network_id]
  subnet_id          = var.subnet_id
  availability_zones = ["${var.region}-01", "${var.region}-02"]

  # Attach the ELB's VIP port to sg-frontend.
  # OTC ELBv3 exposes vip_port_id after creation; we reference it in a
  # separate port-SG association below.

  # No public_ip block → strictly internal, VPC-only.

  tags = var.common_tags
}

# Bind sg-frontend to the ELB's VIP port so OTC enforces the security group.
resource "opentelekomcloud_networking_port_secgroup_associate_v2" "elb_sg" {
  port_id = opentelekomcloud_lb_loadbalancer_v3.wordpress.vip_port_id
  security_group_ids = [
    data.opentelekomcloud_networking_secgroup_v2.sg_frontend.id
  ]
}

################################################################################
# Backend pool  (HTTP, ROUND_ROBIN)
# WordPress backends receive plain HTTP from the ELB; HTTPS is terminated here.
################################################################################

resource "opentelekomcloud_lb_pool_v3" "wordpress_http" {
  name            = "${var.elb_name}-pool-http"
  loadbalancer_id = opentelekomcloud_lb_loadbalancer_v3.wordpress.id
  protocol        = "HTTP"
  lb_algorithm    = "ROUND_ROBIN"

  # Cookie-based session persistence keeps a user on the same WordPress node.
  # This is important for wp-login sessions and WooCommerce carts.
  session_persistence {
    type        = "HTTP_COOKIE"
  }
}

################################################################################
# Backend members  (one per WordPress instance)
################################################################################

#~ resource "opentelekomcloud_lb_member_v3" "wordpress" {
  #~ for_each = var.backend_instances

  #~ name          = "${var.elb_name}-member-${each.key}"
  #~ pool_id       = opentelekomcloud_lb_pool_v3.wordpress_http.id
  #~ address       = each.value
  #~ protocol_port = var.backend_port
  #~ subnet_id     = var.subnet_id

  #~ # weight defaults to 1 – equal distribution across members
#~ }

################################################################################
# Health monitor  (HTTP, checks WordPress's /wp-login.php or /)
################################################################################

resource "opentelekomcloud_lb_monitor_v3" "wordpress" {
  pool_id     = opentelekomcloud_lb_pool_v3.wordpress_http.id
  type        = "HTTP"

  # How often to probe (seconds)
  delay       = 10
  # Probe must succeed within this many seconds
  timeout     = 5
  # Mark UP after this many consecutive successes
  max_retries = 3
  # Mark DOWN after this many consecutive failures
  max_retries_down = 3

  # WordPress always returns 200 on its root; avoid wp-admin (may redirect)
  url_path    = "/"
  http_method = "GET"
  expected_codes = "200,301,302"
}

################################################################################
# Listener 1 – HTTPS on port 443  (TERMINATED_HTTPS)
#
# • Terminates TLS using the certificate above
# • Forwards decrypted HTTP traffic to the backend pool
# • Injects X-Forwarded-Proto: https so WordPress knows the original scheme
#   (required for wp_home / siteurl to generate https:// links)
# • Injects X-Forwarded-For so WordPress sees the real client IP
################################################################################

resource "opentelekomcloud_lb_listener_v3" "https" {
  name            = "${var.elb_name}-listener-https"
  loadbalancer_id = opentelekomcloud_lb_loadbalancer_v3.wordpress.id

  protocol      = "HTTPS"
  protocol_port = 443

  # TLS certificate
  default_tls_container_ref = data.opentelekomcloud_lb_certificate_v3.wordpress.id

  # Recommended TLS 1.2+ (PCI-DSS / best practice)
  # Enforce: TLS-1-2-FS-WITH-1-3  (TLS 1.3 preferred, TLS 1.2 with forward secrecy as fallback)
  tls_ciphers_policy = "tls-1-2-fs-with-1-3"

  # Default pool – sends traffic to WordPress backends over HTTP/80
  default_pool_id = opentelekomcloud_lb_pool_v3.wordpress_http.id

  # Forward the original client IP and scheme so WordPress generates correct URLs
  insert_headers {
    forwarded_for_port = true   # real client IP → X-Forwarded-For
    forwarded_host   = true   # preserve Host header
    #~ transparent_client_ip_enable = true
  }

  # Enable HTTP/2 on the client-facing side for better performance
  http2_enable = true
}

################################################################################
# Listener 2 – HTTP on port 80  (redirect to HTTPS)
#
# All plain-HTTP clients get a 301 redirect to the same URL over HTTPS.
# No backend pool is needed on this listener; the L7 policy handles everything.
################################################################################

resource "opentelekomcloud_lb_listener_v3" "http_redirect" {
  name            = "${var.elb_name}-listener-http"
  loadbalancer_id = opentelekomcloud_lb_loadbalancer_v3.wordpress.id

  protocol      = "HTTP"
  protocol_port = 80

  # No default_pool_id – the L7 policy below handles all requests.
}

################################################################################
# L7 Policy – redirect HTTP → HTTPS (301)
#
# action = REDIRECT_TO_LISTENER points all HTTP/80 traffic to the HTTPS/443
# listener, which then proxies to the backend pool.
################################################################################

resource "opentelekomcloud_lb_l7policy_v2" "http_to_https" {
  name                = "${var.elb_name}-http-to-https"
  action              = "REDIRECT_TO_LISTENER"
  listener_id         = opentelekomcloud_lb_listener_v3.http_redirect.id
  redirect_listener_id = opentelekomcloud_lb_listener_v3.https.id
  description         = "Redirect all HTTP traffic to HTTPS (301)"
  position            = 1
}
