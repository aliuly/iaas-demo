
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

