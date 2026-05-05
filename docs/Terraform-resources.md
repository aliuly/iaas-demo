# Terraform Resource Reference

Links to the provider documentation for every resource and data source used in this project.

---

## OpenTelekomCloud Provider

Provider docs: https://registry.terraform.io/providers/opentelekomcloud/opentelekomcloud/latest/docs

### Networking — VPC

| Resource / Data Source | Used in |
|---|---|
| [`opentelekomcloud_vpc_v1`](https://registry.terraform.io/providers/opentelekomcloud/opentelekomcloud/latest/docs/resources/vpc_v1) | `modules/basis` |
| [`opentelekomcloud_vpc_subnet_v1`](https://registry.terraform.io/providers/opentelekomcloud/opentelekomcloud/latest/docs/resources/vpc_subnet_v1) | `modules/basis` |
| [`opentelekomcloud_vpc_eip_v1`](https://registry.terraform.io/providers/opentelekomcloud/opentelekomcloud/latest/docs/resources/vpc_eip_v1) | `modules/basis`, `vpn_eip.tf` |

### Networking — Security Groups

| Resource / Data Source | Used in |
|---|---|
| [`opentelekomcloud_networking_secgroup_v2`](https://registry.terraform.io/providers/opentelekomcloud/opentelekomcloud/latest/docs/resources/networking_secgroup_v2) | `secgrp.tf` |
| [`opentelekomcloud_networking_secgroup_rule_v2`](https://registry.terraform.io/providers/opentelekomcloud/opentelekomcloud/latest/docs/resources/networking_secgroup_rule_v2) | `secgrp.tf` |
| [`opentelekomcloud_networking_port_secgroup_associate_v2`](https://registry.terraform.io/providers/opentelekomcloud/opentelekomcloud/latest/docs/resources/networking_port_secgroup_associate_v2) | `modules/apps` |
| `data` [`opentelekomcloud_networking_secgroup_v2`](https://registry.terraform.io/providers/opentelekomcloud/opentelekomcloud/latest/docs/data-sources/networking_secgroup_v2) | `modules/frontend` |

### NAT Gateway

| Resource / Data Source | Used in |
|---|---|
| [`opentelekomcloud_nat_gateway_v2`](https://registry.terraform.io/providers/opentelekomcloud/opentelekomcloud/latest/docs/resources/nat_gateway_v2) | `modules/basis` |
| [`opentelekomcloud_nat_snat_rule_v2`](https://registry.terraform.io/providers/opentelekomcloud/opentelekomcloud/latest/docs/resources/nat_snat_rule_v2) | `modules/basis` |
| [`opentelekomcloud_nat_dnat_rule_v2`](https://registry.terraform.io/providers/opentelekomcloud/opentelekomcloud/latest/docs/resources/nat_dnat_rule_v2) | `modules/bastion` |

### Enterprise VPN

| Resource / Data Source | Used in |
|---|---|
| [`opentelekomcloud_enterprise_vpn_gateway_v5`](https://registry.terraform.io/providers/opentelekomcloud/opentelekomcloud/latest/docs/resources/enterprise_vpn_gateway_v5) | `modules/vpn` |
| [`opentelekomcloud_enterprise_vpn_customer_gateway_v5`](https://registry.terraform.io/providers/opentelekomcloud/opentelekomcloud/latest/docs/resources/enterprise_vpn_customer_gateway_v5) | `modules/vpn` |
| [`opentelekomcloud_enterprise_vpn_connection_v5`](https://registry.terraform.io/providers/opentelekomcloud/opentelekomcloud/latest/docs/resources/enterprise_vpn_connection_v5) | `modules/vpn` |

### Load Balancer (ELBv3)

| Resource / Data Source | Used in |
|---|---|
| [`opentelekomcloud_lb_loadbalancer_v3`](https://registry.terraform.io/providers/opentelekomcloud/opentelekomcloud/latest/docs/resources/lb_loadbalancer_v3) | `modules/frontend` |
| [`opentelekomcloud_lb_listener_v3`](https://registry.terraform.io/providers/opentelekomcloud/opentelekomcloud/latest/docs/resources/lb_listener_v3) | `modules/frontend` |
| [`opentelekomcloud_lb_pool_v3`](https://registry.terraform.io/providers/opentelekomcloud/opentelekomcloud/latest/docs/resources/lb_pool_v3) | `modules/frontend` |
| [`opentelekomcloud_lb_member_v3`](https://registry.terraform.io/providers/opentelekomcloud/opentelekomcloud/latest/docs/resources/lb_member_v3) | `modules/apps` |
| [`opentelekomcloud_lb_monitor_v3`](https://registry.terraform.io/providers/opentelekomcloud/opentelekomcloud/latest/docs/resources/lb_monitor_v3) | `modules/frontend` |
| [`opentelekomcloud_lb_l7policy_v2`](https://registry.terraform.io/providers/opentelekomcloud/opentelekomcloud/latest/docs/resources/lb_l7policy_v2) | `modules/frontend` |
| [`opentelekomcloud_lb_certificate_v3`](https://registry.terraform.io/providers/opentelekomcloud/opentelekomcloud/latest/docs/resources/lb_certificate_v3) | `modules/frontend` |

### Compute (ECS)

| Resource / Data Source | Used in |
|---|---|
| [`opentelekomcloud_compute_instance_v2`](https://registry.terraform.io/providers/opentelekomcloud/opentelekomcloud/latest/docs/resources/compute_instance_v2) | `modules/bastion`, `modules/apps` |
| [`opentelekomcloud_compute_keypair_v2`](https://registry.terraform.io/providers/opentelekomcloud/opentelekomcloud/latest/docs/resources/compute_keypair_v2) | `modules/apps` |
| `data` [`opentelekomcloud_images_image_v2`](https://registry.terraform.io/providers/opentelekomcloud/opentelekomcloud/latest/docs/data-sources/images_image_v2) | `common.tf` |

### Auto Scaling (AS)

| Resource / Data Source | Used in |
|---|---|
| [`opentelekomcloud_as_configuration_v1`](https://registry.terraform.io/providers/opentelekomcloud/opentelekomcloud/latest/docs/resources/as_configuration_v1) | `modules/apps` |
| [`opentelekomcloud_as_group_v1`](https://registry.terraform.io/providers/opentelekomcloud/opentelekomcloud/latest/docs/resources/as_group_v1) | `modules/apps` |

### DNS

| Resource / Data Source | Used in |
|---|---|
| [`opentelekomcloud_dns_recordset_v2`](https://registry.terraform.io/providers/opentelekomcloud/opentelekomcloud/latest/docs/resources/dns_recordset_v2) | `modules/bastion`, `modules/vpn`, `modules/frontend` |
| `data` [`opentelekomcloud_dns_zone_v2`](https://registry.terraform.io/providers/opentelekomcloud/opentelekomcloud/latest/docs/data-sources/dns_zone_v2) | `modules/bastion`, `modules/vpn`, `modules/frontend` |

### RDS (Relational Database Service)

| Resource / Data Source | Used in |
|---|---|
| [`opentelekomcloud_rds_instance_v3`](https://registry.terraform.io/providers/opentelekomcloud/opentelekomcloud/latest/docs/resources/rds_instance_v3) | `modules/datastore` |

### SFS Turbo (Shared File System)

| Resource / Data Source | Used in |
|---|---|
| [`opentelekomcloud_sfs_turbo_share_v1`](https://registry.terraform.io/providers/opentelekomcloud/opentelekomcloud/latest/docs/resources/sfs_turbo_share_v1) | `modules/datastore` |

### CBR (Cloud Backup and Recovery)

| Resource / Data Source | Used in |
|---|---|
| [`opentelekomcloud_cbr_vault_v3`](https://registry.terraform.io/providers/opentelekomcloud/opentelekomcloud/latest/docs/resources/cbr_vault_v3) | `modules/apps` |
| [`opentelekomcloud_cbr_policy_v3`](https://registry.terraform.io/providers/opentelekomcloud/opentelekomcloud/latest/docs/resources/cbr_policy_v3) | `modules/apps` |

---

## ACME Provider (Let's Encrypt)

Provider docs: https://registry.terraform.io/providers/vancluever/acme/latest/docs

| Resource / Data Source | Used in |
|---|---|
| [`acme_registration`](https://registry.terraform.io/providers/vancluever/acme/latest/docs/resources/registration) | `modules/acme` |
| [`acme_certificate`](https://registry.terraform.io/providers/vancluever/acme/latest/docs/resources/certificate) | `modules/acme` |

---

## TLS Provider

Provider docs: https://registry.terraform.io/providers/hashicorp/tls/latest/docs

| Resource / Data Source | Used in |
|---|---|
| [`tls_private_key`](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | `modules/acme` |
