# IaaS-demo

T Cloud Public IaaS Demo

It assumes connectivity to an On Prem network via a VPN.  The On
Prem network host an IdP based on authentik and client systems.

# Pre-requisistes

To deploy this project you need a [T Cloud Public](https://public.t-cloud.com/en)
tenant.  Normally I would create a specific project to host this tenant.
This project assumes private communication to clients systems via
a VPN.  The code here will create a VPC and wire up the VPN, but the
peer VPN gateway needs to exist already.

You will need the following credentials:

* Tenant administrator - to deploy the bulk of the code.  I would
  provide these credentials as environment variables. See
  [Terraform Provider](https://registry.terraform.io/providers/opentelekomcloud/opentelekomcloud/latest/docs#authentication).
  I would recommend using AK/SK credentials.  Place them in an `env`
  file in `1-infra`:
  ```bash
  export OS_ACCESS_KEY=".... CHANGE ME ...."
  export OS_SECRET_KEY=".... CHANGE ME ...."
  export OS_PROJECT_NAME=".... CHANGE ME ...."

  ```
* User with DNS Admin rights - for the ACME DNS-01 handshake needed for
  issuing TLS certificates.  These need to be configure in a `tfvars`
  file.
  ```hcl
  acme_otc_creds = {
    OTC_USER_NAME    = ".... CHANGE ME ...."
    OTC_PASSWORD     = ".... CHANGE ME ...."
    OTC_DOMAIN_NAME  = "OTC000.... CHANGE ME ...."
    OTC_PROJECT_NAME = "eu-de_.... CHANGE ME ...."
  }
  ```
  Note the ACME `otc` provider only uspport username/password
  authentication.  The user specified here *ONLY* needs access
  to the DNS infrastructure of T Cloud Public.
* If using the remote backend for storing state, you need an account
  with Read/Write access to that bucket.  This is configured in
  `backend.hcl`.
  ```hcl
  #
  # Configure S3 backend
  #
  bucket                      = ".... CHANGE ME ...."
  key                         = "".... CHANGE ME ...."/terraform.tfstate"
  region                      = "eu-de"
  endpoint                    = "https://obs.eu-de.otc.t-systems.com"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
  use_path_style              = true
  use_lockfile                = true
  ```
