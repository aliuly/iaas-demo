# IaaS Demo — T Cloud Public

A [OpenTofu](https://opentofu.org/) deployment that provisions a production-style WordPress environment on [T Cloud Public](https://public.t-cloud.com/en) (Open Telekom Cloud). The environment connects to an on-premises network via VPN and uses [Authentik](https://goauthentik.io/) as an SSO identity provider.
The appliction is set-up as an internal facing application.

---

## Architecture

```
Internet
   │
   ├─── Bastion host (SSH :22, HTTPS :443)   ← EIP (admin subnet)
   │
   └─── ELB / Load Balancer (HTTPS :443)     ← EIP (frontend subnet)
              │
              └── WordPress App Servers       (apps subnet, Auto-Scaling)
                       │            │
                  PostgreSQL      NFS/SFS     (db subnet)

On-Prem Network (via IPsec VPN)
   └── Authentik IdP
   └── Client workstations
```

### VPC subnets (`netprefix` = `10.x`)

| Subnet | CIDR | Purpose |
|---|---|---|
| `sn-cass1-admin` | `<prefix>.160.0/24` | Bastion host, NAT gateway |
| `sn-cass3-fe` | `<prefix>.43.0/24` | ELB / load balancer |
| `sn-cass3-apps` | `<prefix>.4.0/24` | WordPress app servers |
| `sn-cass3-db` | `<prefix>.3.0/24` | RDS PostgreSQL, SFS share |

### Modules

| Module | Path | What it creates |
|---|---|---|
| `basis` | `modules/basis` | VPC, subnets, NAT gateway, shared outbound EIP |
| `acme` | `modules/acme` | TLS certificate via Let's Encrypt (ACME DNS-01) |
| `bastion` | `modules/bastion` | Jump host with public EIP and local user accounts |
| `vpn` | `modules/vpn` | IPsec VPN gateway (dual EIP, HA) connecting to on-prem |
| `datastore` | `modules/datastore` | RDS PostgreSQL (HA) + SFS NFS share |
| `apps` | `modules/apps` | WordPress instances, auto-scaling group, cloud-init config |
| `frontend` | `modules/frontend` | ELBv3 load balancer, TLS termination, DNS record |

### Security groups

| Group | Inbound rules |
|---|---|
| `sg-bastions` | TCP 22 and 443 from anywhere |
| `sg-frontend` | TCP 80 and 443 from `10.0.0.0/8` (VPC or On Prem networks) |
| `sg-appsrv` | TCP 22 from bastions; TCP 80 from frontend and bastions; TCP 80 from frontend subnet CIDR (ELB health checks) |
| `sg-postgres` | TCP 5432 from app servers; TCP/UDP 111, 2049, 20048 from app servers (NFS) |

---

## Prerequisites

1. **T Cloud Public tenant** — obtain a tenant and create a dedicated project.

2. **Peer VPN gateway** — the on-prem IPsec endpoint must exist before `tofu apply`. Terraform creates the cloud-side VPN gateway; it does not configure the on-prem peer.

3. **Authentik IdP** — running and reachable from the WordPress instances. Configure Authentik *before* running `tofu apply`. See [`docs/AUTHENTIK-SETUP.md`](docs/AUTHENTIK-SETUP.md) for the full step-by-step guide.

4. **OpenTofu ≥ 1.6** installed locally.

5. **S3-compatible bucket** for remote state (optional but recommended). Configure in `backend.hcl`.
   Note that this bucket does not have to be part of the T Cloud Public
   project used to hold the infrastructure.

---

## Credentials & configuration

### Provider credentials (AK/SK)

Place these in a `.env` file in the project root (loaded automatically by `scripts/tf`):

```bash
export OS_ACCESS_KEY="your-access-key"
export OS_SECRET_KEY="your-secret-key"
export OS_PROJECT_NAME="eu-de_your-project"
```

Refer to the
[Terraform Provider](https://registry.terraform.io/providers/opentelekomcloud/opentelekomcloud/latest/docs#authentication)
documentation for other authentication credential options.


### Variable files

Create a `terraform.tfvars` (or copy and edit `dev.tfvars`) with at minimum:

```hcl
# Networking
netprefix    = "10.9"                          # First two octets of VPC CIDR
dns_zone     = "example.public.t-cloud.com"

# VPN
vpn_psk      = "your-pre-shared-key"
peer_subnets = ["192.168.0.0/16"]              # On-prem networks

# Cloud login user (injected via cloud-init)
cloud_user = {
  passwd   = "hashed-password"                 # openssl passwd -6
  ssh_keys = ["ssh-rsa AAAA..."]
}

# Bastion local accounts
local_users = [
  { name = "alice", passwd = "hashed", ssh_keys = ["ssh-rsa AAAA..."] }
]

# Database
db_passwd    = "postgres-root-password"
wp_rds_passwd = "wordpress-db-password"

# WordPress
wp_domain         = "wp-demo1.example.public.t-cloud.com"
wp_admin_email    = "admin@example.com"
wp_admin_passwd   = "wp-admin-password"

# Authentik SSO (configure Authentik first — see docs/AUTHENTIK-SETUP.md)
authentik_base_url      = "https://auth.example.com"
authentik_client_id     = "your-client-id"
authentik_client_secret = "your-client-secret"

# TLS certificates (Let's Encrypt)
le_email = "you@example.com"
acme_otc_creds = {
  OTC_USER_NAME    = "dns-admin-user"
  OTC_PASSWORD     = "dns-admin-password"
  OTC_DOMAIN_NAME  = "OTC000000000000000"
  OTC_PROJECT_NAME = "eu-de_your-project"
}
```
The `acme_otc_creds` is an account that can manage the zone that we
are using for DNS-01 challenges.  My recommendation is to use
an account specifically for that purpose.

### Remote state backend (`backend.hcl`)

```hcl
bucket                      = "your-state-bucket"
key                         = "your-project/terraform.tfstate"
region                      = "eu-de"
endpoint                    = "https://obs.eu-de.otc.t-systems.com"
skip_credentials_validation = true
skip_metadata_api_check     = true
skip_region_validation      = true
use_path_style              = true
use_lockfile                = true
```

---

## Deployment

Use the `scripts/tf` wrapper (recommended). It auto-loads `*.env` and `*.tfvars` files from the project directory, maps OTC credentials to AWS env vars for the S3 backend, and derives the region from `OS_PROJECT_NAME`.

```bash
# 1. Configure Authentik — see docs/AUTHENTIK-SETUP.md (Steps 1–4)

# 2. Initialise (downloads providers, configures backend)
./scripts/tf init

# 3. Review the plan
./scripts/tf plan

# 4. Apply
./scripts/tf apply
```

You can also call `tofu` directly; the wrapper just saves you from passing `-var-file` and environment flags manually.

> **Note:** The ACME provider is pointed at the Let's Encrypt *staging* server by default (`versions.tf`). Switch to the production URL before your first real deploy:
>
> ```hcl
> # versions.tf — uncomment the production line
> server_url = "https://acme-v02.api.letsencrypt.org/directory"
> ```

---

## Outputs

After a successful apply, `tofu output` (or `./scripts/tf output`) shows:

| Output | Description |
|---|---|
| `vpc_id` | VPC resource ID |
| `natgw_id` | NAT gateway ID |
| `dns_vpngw` | DNS names for both VPN gateway EIPs (give these to the on-prem admin) |
| `sg_ids` | Map of security group IDs |
| `bastion_ext_ip` / `bastion_ext_dns` | Bastion public IP and DNS name |
| `bastion_int_ip` / `bastion_int_dns` | Bastion private IP and DNS name |
| `rds` | PostgreSQL endpoint details (AZ, IPs, FQDN, port) |
| `sfs` | NFS share export location and metadata |
| `apps` | App-server module outputs |
| `frontend` | Load balancer module outputs |
| `acme_common_name` | TLS certificate CN |
| `acme_expiration` | TLS certificate expiry date |
| `acme_cert_id` / `acme_cert_name` | Certificate identifiers in OTC SCM |

---

## Scripts

| Script | Purpose |
|---|---|
| `scripts/tf` | OpenTofu wrapper — loads env/var files, maps credentials, derives region |
| `scripts/pack` | Packaging helper |
| `scripts/xvars` | Variable extraction utility |
| `scripts/dns2ip` | Resolves DNS names to IPs |
| `scripts/tidy` | Clean-up resources. |

---

## Further reading

- [`docs/Setup-authentik.md`](docs/Setup-authentik.md) — Step-by-step guide to configuring Authentik OAuth2/OIDC for WordPress SSO
- [`docs/Compliance.md`](docs/Compliance.md) — Compliance notes
- [`docs/scripts.md`](docs/scripts.md) — In-depth documentation for all scripts in `scripts/`
- [`docs/Terraform-resources.md`](docs/Terraform-resources.md) — Links to provider docs for every resource and data source used
- [OpenTelekomCloud Terraform Provider](https://registry.terraform.io/providers/opentelekomcloud/opentelekomcloud/latest/docs)
- [ACME Provider](https://registry.terraform.io/providers/vancluever/acme/latest/docs)

---

## License

Copyright (c) 2026 aliuly. Released under the MIT License — see [LICENSE](LICENSE) for full details.
