#!/bin/bash
# ── ComplianceAsCode hardening ────────────────────────────────────────────────
# Fetch Ubuntu 22.04 SCAP content from the latest ComplianceAsCode release,
# generate a Bash remediation script, apply it, then scan to produce a report.
set -euo pipefail
SCAP_DIR=/usr/share/xml/scap/ssg/content
SCAP_XML=${SCAP_DIR}/ssg-ubuntu2204-ds.xml
REPORTER=www-idp1.cassiopeia.public.t-cloud.com/security-reports
# PROFILE=xccdf_org.ssgproject.content_profile_standard
PROFILE=xccdf_org.ssgproject.content_profile_cis_level1_server
# PROFILE=xccdf_org.ssgproject.content_profile_cis_level2_server
#
if [ ! -f "${SCAP_XML}" ]; then
  VER=$(curl -sSL https://api.github.com/repos/ComplianceAsCode/content/releases/latest \
	| jq -r .tag_name | sed 's/^v//')
  ZIP=/tmp/ssg-${VER}.zip
  curl -sL \
    "https://github.com/ComplianceAsCode/content/releases/download/v${VER}/scap-security-guide-${VER}.zip" \
    -o "${ZIP}"
  mkdir -p "${SCAP_DIR}"
  unzip -j "${ZIP}" "scap-security-guide-${VER}/ssg-ubuntu2204-ds.xml" -d "${SCAP_DIR}"
  rm -f "${ZIP}"
fi
#
# Generate Bash remediation script and apply it
oscap xccdf generate fix \
  --profile "${PROFILE}" \
  --fix-type bash \
  --output /root/harden-oscap.sh \
  "${SCAP_XML}"
bash /root/harden-oscap.sh || true
#
# Scan and save HTML report for review
oscap xccdf eval \
  --profile  "${PROFILE}" \
  --report   /root/oscap-scan.html \
  --results  /root/oscap-results.xml \
  "${SCAP_XML}" || true

[ -n "${REPORTER}" ] \
	&& curl \
	  -X PUT \
	  -d @/root/oscap-scan.html \
	  "https://$REPORTER/?filename=$(uname -n).html"


