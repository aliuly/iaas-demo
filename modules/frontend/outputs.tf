output "elb_id" {
  description = "ID of the Elastic Load Balancer"
  value       = opentelekomcloud_lb_loadbalancer_v3.wordpress.id
}

output "elb_vip_address" {
  description = "Private VIP address of the ELB (use this in your internal DNS / Route 53 / OTC DNS)"
  value       = opentelekomcloud_lb_loadbalancer_v3.wordpress.vip_address
}

output "elb_vip_port_id" {
  description = "Neutron port ID of the ELB VIP (useful for attaching additional security groups)"
  value       = opentelekomcloud_lb_loadbalancer_v3.wordpress.vip_port_id
}

output "https_listener_id" {
  description = "ID of the HTTPS (TERMINATED_HTTPS) listener"
  value       = opentelekomcloud_lb_listener_v3.https.id
}

output "http_listener_id" {
  description = "ID of the HTTP redirect listener"
  value       = opentelekomcloud_lb_listener_v3.http_redirect.id
}

output "backend_pool_id" {
  description = "ID of the WordPress HTTP backend pool"
  value       = opentelekomcloud_lb_pool_v3.wordpress_http.id
}

output "backend_port" {
  description = "Port the backend pool listens on — needed by AS lbaas_listeners block"
  value       = var.backend_port
}

