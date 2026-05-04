

* [x] hardening
  - reports in NFS files
  - nginx to show them directly (by-passing WordPress)
* [ ] verify working conditions!
* [ ] EVS and SFS encryption
* [x] check nginx configure so it is always default
* [x] set-up Authentik
  - testing
  - https://<wordpress_domain>/wp-admin/admin-ajax.php?action=openid-connect-authorize
  - https://wp-demo1.cassiopeia.public.t-cloud.com/wp-admin/admin-ajax.php?action=openid-connect-authorize
- Backup concept
  - [x] SFS hourly backups ... restore from backup in new AZ
  - [x] PostgreSQL in HA mode on two AZs
  - [x] App Server - Two AutoScaling sets, prod set to desired capacity, DR AS set to zero.
    DR, Prod is zero, AG is set to desired capacity
  - [x] ELB 2-AZ redundant

***

* [ ] ~~bastion should manage TLS on LB~~
  * certbot, install cert
  * agency: DNS, ELB
  * For now, we will manually issue them and install them by hand.
  * IdP will be issuing certificates.



