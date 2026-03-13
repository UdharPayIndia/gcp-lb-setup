#!/bin/bash
# ==============================================================================
# 01_dns_auth.sh — Create DNS Authorizations for Certificate Manager
# ==============================================================================
# This script creates DNS authorization resources for each domain.
# You must add the resulting CNAME records to your DNS provider.
# ==============================================================================

set -euo pipefail

PROJECT_ID="${GCP_PROJECT_ID:?Set GCP_PROJECT_ID env var}"
DOMAINS=(
  "rocketpay.co.in"
  "udharpay.com"
)

echo "=== Step 1: Create DNS Authorizations ==="

for DOMAIN in "${DOMAINS[@]}"; do
  # Replace dots and asterisks with dashes for resource names
  AUTH_NAME="auth-${DOMAIN//[*.]/-}"
  # Clean up leading/trailing dashes if any
  AUTH_NAME="${AUTH_NAME#-}"
  
  echo "Creating DNS authorization for: $DOMAIN (Resource: $AUTH_NAME)"
  
  # Check if it already exists
  if gcloud certificate-manager dns-authorizations describe "$AUTH_NAME" --project="$PROJECT_ID" >/dev/null 2>&1; then
    echo "  -> DNS authorization $AUTH_NAME already exists."
  else
    gcloud certificate-manager dns-authorizations create "$AUTH_NAME" \
      --project="$PROJECT_ID" \
      --domain="$DOMAIN" \
      --quiet
  fi

  echo "  -> DNS Record to add to your DNS provider:"
  gcloud certificate-manager dns-authorizations describe "$AUTH_NAME" \
    --project="$PROJECT_ID" \
    --format="table(dnsResourceRecord.name, dnsResourceRecord.type, dnsResourceRecord.data)"
  echo ""
done

echo "============================================="
echo "  DNS Authorizations Created!"
echo "============================================="
echo "Please add the CNAME records above to your DNS provider (e.g., Cloudflare, Route53, GoDaddy)."
echo "Wait for DNS propagation before running 02_create_cert.sh."
