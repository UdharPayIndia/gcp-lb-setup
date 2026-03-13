#!/bin/bash
# ==============================================================================
# 02_create_cert.sh — Create Managed Certificate using DNS Authorizations
# ==============================================================================
# This script creates a certificate resource that references the 
# DNS authorizations created in 01_dns_auth.sh.
# ==============================================================================

set -euo pipefail

PROJECT_ID="${GCP_PROJECT_ID:?Set GCP_PROJECT_ID env var}"
CERT_NAME="stage-cert-rocketpay-udharpay"
CERT_DOMAINS=(
  "*.rocketpay.co.in"
  "*.udharpay.com"
)

AUTH_IDS=""
for DOMAIN in "${CERT_DOMAINS[@]}"; do
  # Extract parent domain (e.g. *.rocketpay.co.in -> rocketpay.co.in)
  PARENT_DOMAIN="${DOMAIN#\*.}"
  # Replace dots with dashes for resource name
  AUTH_NAME="auth-${PARENT_DOMAIN//./-}"
  
  AUTH_ID="projects/${PROJECT_ID}/locations/global/dnsAuthorizations/${AUTH_NAME}"
  
  # Append to list
  if [ -z "$AUTH_IDS" ]; then
    AUTH_IDS="$AUTH_ID"
  else
    AUTH_IDS="${AUTH_IDS},${AUTH_ID}"
  fi
done

CERT_DOMAINS_STR=$(IFS=, ; echo "${CERT_DOMAINS[*]}")
echo "CERT_DOMAINS_STR: $CERT_DOMAINS_STR"
echo "AUTH_IDS: $AUTH_IDS"

echo "=== Creating Managed Certificate: $CERT_NAME ==="
echo "Domains: $CERT_DOMAINS_STR"
echo "Referencing DNS Authorizations: $AUTH_IDS"

gcloud certificate-manager certificates create "$CERT_NAME" \
  --domains="$CERT_DOMAINS_STR" \
  --dns-authorizations="$AUTH_IDS" \
  --quiet

echo ""
echo "============================================="
echo "  Certificate Creation Initiated!"
echo "============================================="
echo "The certificate is now being provisioned."
echo "Verify status with: gcloud certificate-manager certificates describe $CERT_NAME --project=$PROJECT_ID"
