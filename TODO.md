

* [ ] hardening
  - reports in NFS files
  - nginx to show them directly (by-passing WordPress)
* [ ] verify working conditions!
* [ ] EVS and SFS encryption
* [x] check nginx configure so it is always default
* [x] set-up Authentik
  - testing
  - https://<wordpress_domain>/wp-admin/admin-ajax.php?action=openid-connect-authorize
  - https://wp-demo1.cassiopeia.public.t-cloud.com/wp-admin/admin-ajax.php?action=openid-connect-authorize
  - Client ID: r9GQxLxggVNZ0WcmNE08INfHCdDApbFbKxJILnq6
  - Client Secret: 2Xm8NUFSTUL34KgRJh9FxL4BHhepEzrcLLKKUYORd7vWDPaGDldI6KmE3MrDDJtJiJ0iq91jVTOmIE31DM2QVPIQVrLSuxGUjjEtvSZWQNxftLRb2zYpTTWLuXUHADLf
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


# Authentik set-up overview

This is a technical configuration guide, so a clean markdown document is the right format. Let me write comprehensive Authentik configuration instructions that match exactly what the Terraform deployment expects.The guide covers the full setup in 8 steps, all tied directly to the values the Terraform deployment expects:

**Steps 1–3** are the core Authentik configuration — property mapping (to emit `preferred_username`, which is the `identity_key` the plugin is configured to use), the OAuth2/OpenID provider (where you get the client ID and secret to put in `terraform.tfvars`), and the application wrapper.

**Step 4** covers access control via group bindings — important since without it every Authentik user can reach WordPress.

**Step 5** lists all the endpoint URLs the cloud-init script constructs from `authentik_base_url`, with a `curl` snippet to verify the discovery document is reachable from your network before deploying.

**Step 6** shows exactly which `terraform.tfvars` keys to fill in and confirms a `tofu apply` is all that's needed to push the credentials to running instances.

**Step 7** has a troubleshooting section covering the most common failure modes — missing button, redirect URI mismatch, `preferred_username` missing, redirect loops, and role assignment.

**Step 8** is an optional hardening step to disable the standard password login form entirely once SSO is confirmed working, along with a warning to keep a break-glass procedure in place first.


# ComplianceAsCode/Content

This is the industry-standard "Compliance as Code" repository. It serves as a single source of truth where compliance requirements (like **CIS**, **STIG**, **PCI-DSS**, and **HIPAA**) are written in a format-agnostic way and then "built" into actionable automation for various tools.

## Key Features of `ComplianceAsCode/content`

* **HTML Reports:** When you run a scan using the **OpenSCAP** scanner (which consumes the content from this repo), it generates an interactive HTML report showing every passed/failed rule with detailed technical justifications.
* **Ansible Output:** The build system generates **Ansible Playbooks** for every profile. These playbooks are designed to remediate (fix) a system so that it aligns with the selected compliance baseline.
* **Bash Scripts:** Similar to Ansible, the repo generates **Bash remediation scripts** for environments where Ansible might not be available.
* **SCAP/OVAL:** It outputs the XML-based formats required by enterprise scanners and the `oscap` command-line tool.

---

## How to use it

### 1. Generating Remediation Code
You don't just "download" a script; you typically generate it based on a specific **Profile** (e.g., "Standard System Security Profile for Ubuntu").

If you have `openscap-utils` installed, you can generate a Bash remediation script from the compiled content like this:
```bash
# Generate a Bash script to fix a system based on the PCI-DSS profile
oscap xccdf generate fix --profile pci-pss --fix-type bash \
--output remediate_pci.sh ssg-rhel8-ds.xml
```

### 2. Running a Scan & Generating the HTML Report
To see where your system stands before fixing it:
```bash
oscap xccdf eval --profile xccdf_org.ssgproject.content_profile_stig \
--results results.xml \
--report report.html \
/usr/share/xml/scap/ssg/content/ssg-rhel9-ds.xml
```
*The resulting `report.html` is a professional, high-level dashboard for auditors.*

---

## Repository & Resources
* **GitHub Repo:** [ComplianceAsCode/content](https://github.com/ComplianceAsCode/content)
* **Supported Platforms:** RHEL, CentOS, Fedora, Ubuntu, Debian, SUSE, macOS, and even specialized platforms like OpenShift and AWS.

### Alternative: DevSec Hardening Framework
If you want something purely focused on Ansible without the "SCAP" overhead, check out the [DevSec Hardening Framework](https://github.com/dev-sec). They provide highly-rated Ansible roles (like `ansible-os-hardening`) and use **InSpec** for the "Code" part of compliance checking, which also generates clean reports.

