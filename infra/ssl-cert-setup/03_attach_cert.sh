#!/bin/bash
# ==============================================================================
# 03_attach_cert.sh — Create Certificate Map and Attach to Load Balancer
# ==============================================================================
# This script creates a Certificate Map, adds entries for each domain,
# and attaches the map to the Target HTTPS Proxy of the Load Balancer.
# ==============================================================================

set -euo pipefail

PROJECT_ID="${GCP_PROJECT_ID:?Set GCP_PROJECT_ID env var}"
MAP_NAME="stage-cert-map"
CERT_NAME="stage-cert-rocketpay-udharpay"
TARGET_HTTPS_PROXY="stage-lb-as1-api-services-and-target-proxy"

DOMAINS=(
  "api-staging.rocketpay.co.in"
  "stage-api-pg.rocketpay.co.in"
  "admin-staging.udharpay.com"
  "staging-distributor.rocketpay.co.in"
  "merchant.rocketpay.co.in"
  "stage-merchant.rocketpay.co.in"
  "gcp-api-staging.rocketpay.co.in"
  "gcp-stage-api-pg.rocketpay.co.in"
  "gcp-admin-staging.udharpay.com"
  "gcp-staging-distributor.rocketpay.co.in"
  "staging-payment-schedule-customer.rocketpay.co.in"
  "checkout-staging.rocketpay.co.in"
  "checkout-staging.udharpay.com"
)

echo "=== Step 1: Create Certificate Map ==="
if gcloud certificate-manager maps describe "$MAP_NAME" --project="$PROJECT_ID" >/dev/null 2>&1; then
  echo "  -> Certificate map $MAP_NAME already exists."
else
  gcloud certificate-manager maps create "$MAP_NAME" \
    --project="$PROJECT_ID" \
    --quiet
fi

echo "=== Step 2: Create Map Entries for each Domain ==="
for DOMAIN in "${DOMAINS[@]}"; do
  ENTRY_NAME="entry-${DOMAIN//[*.]/-}"
  ENTRY_NAME="${ENTRY_NAME#-}"
  echo "Adding entry for: $DOMAIN (Entry: $ENTRY_NAME)"
  
  if gcloud certificate-manager maps entries describe "$ENTRY_NAME" --map="$MAP_NAME" --project="$PROJECT_ID" >/dev/null 2>&1; then
     echo "  -> Entry $ENTRY_NAME already exists."
  else
    gcloud certificate-manager maps entries create "$ENTRY_NAME" \
      --project="$PROJECT_ID" \
      --map="$MAP_NAME" \
      --certificates="$CERT_NAME" \
      --hostname="$DOMAIN" \
      --quiet
  fi
done

echo "=== Step 3: Attach Certificate Map to Target HTTPS Proxy ==="
# Note: This replaces the list of ssl-certificates with a certificate-map.
# Warning: Ensure the certificate is provisioned before attaching for live traffic.

read -p "Do you want to attach the Certificate Map to the Target HTTPS Proxy now? (y/N): " ATTACH_CONFIRM
ATTACH_CONFIRM=${ATTACH_CONFIRM:-n}

if [[ "$ATTACH_CONFIRM" =~ ^[Yy]$ ]]; then
  echo "Attaching map to proxy..."
  gcloud compute target-https-proxies update "$TARGET_HTTPS_PROXY" \
    --project="$PROJECT_ID" \
    --certificate-map="$MAP_NAME" \
    --global \
    --quiet
  
  echo ""
  echo "============================================="
  echo "  Certificate Map Attached to Load Balancer!"
  echo "============================================="
  echo "Map Name: $MAP_NAME"
  echo "Proxy:    $TARGET_HTTPS_PROXY"
  echo "============================================="
else
  echo ""
  echo "============================================="
  echo "  Skipped Attaching to Load Balancer."
  echo "============================================="
  echo "Map Name: $MAP_NAME"
  echo "To attach later, run:"
  echo "gcloud compute target-https-proxies update $TARGET_HTTPS_PROXY --project=$PROJECT_ID --certificate-map=$MAP_NAME --global"
  echo "============================================="
fi
