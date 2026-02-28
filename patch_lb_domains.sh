#!/bin/bash
# ==============================================================================
# patch_lb_domains.sh — Patch live Load Balancer with new domains and SSL
# ==============================================================================
# This script applies the domain changes and SSL updates to the live 
# GCP load balancer 'stage-lb-as1-udharpay-api'.
# ==============================================================================

set -euo pipefail

PROJECT_ID="${GCP_PROJECT_ID:?Set GCP_PROJECT_ID env var}"
URL_MAP_NAME="stage-lb-as1-udharpay-api"
OLD_SSL_CERT="stage-ssl-as1-udharpay-api"
NEW_SSL_CERT="stage-ssl-as1-udharpay-api-v3"
TARGET_HTTPS_PROXY="stage-targetproxy-as1-udharpay-api-https"

# New domains
API_STAGING_DOMAIN="api-staging.rocketpay.co.in"
RPG_STAGING_DOMAIN="stage-api-pg.rocketpay.co.in"
ADMIN_STAGING_DOMAIN="admin-staging.udharpay.com"
DISTRIBUTOR_STAGING_DOMAIN="staging-distributor.rocketpay.co.in"

SSL_DOMAINS="${API_STAGING_DOMAIN},${RPG_STAGING_DOMAIN},${ADMIN_STAGING_DOMAIN},${DISTRIBUTOR_STAGING_DOMAIN}"

echo "=== Step 1: Create New Google-Managed SSL Certificate ==="
echo "Domains: $SSL_DOMAINS"
gcloud compute ssl-certificates create "$NEW_SSL_CERT" \
  --project="$PROJECT_ID" \
  --domains="$SSL_DOMAINS" \
  --global \
  --quiet

echo "=== Step 2: Update HTTPS Target Proxy to use New SSL Certificate ==="
gcloud compute target-https-proxies update "$TARGET_HTTPS_PROXY" \
  --project="$PROJECT_ID" \
  --ssl-certificates="$NEW_SSL_CERT" \
  --global \
  --quiet

echo "=== Step 3: Update Host Rules in URL Map ==="

# Note: We need to use 'gcloud compute url-maps add-host-rule' or 'import'
# Since we are changing existing hosts, we will use a temporary YAML to patch.

TMP_URL_MAP="/tmp/live-url-map-patch.yaml"

echo "Fetching current URL map..."
gcloud compute url-maps describe "$URL_MAP_NAME" --project="$PROJECT_ID" --global > "$TMP_URL_MAP"

# Use sed to replace old internal host names with new public domains if they were used
# Based on 02_rules.sh, RPG host was 'gcp-staging-api-pg'
# and Admin host was 'admin-staging.udharpay.com' (already correct but we'll ensure)

echo "Patching URL map YAML..."
# Replace RPG host
sed -i.bak "s/gcp-staging-api-pg/${RPG_STAGING_DOMAIN}/g" "$TMP_URL_MAP"

# Replace Distributor host
sed -i.bak "s/gcp-staging-distributor.rocketpay.co.in/${DISTRIBUTOR_STAGING_DOMAIN}/g" "$TMP_URL_MAP"

# Ensure the '*' host (main-paths) supports api-staging.rocketpay.co.in
# Actually, the defaultService and '*' host rule handle the main API paths.
# We should probably add an explicit host rule for api-staging.rocketpay.co.in 
# to ensure it's mapped to main-paths.

# Let's check if 'api-staging.rocketpay.co.in' should be in hostRules.
# In the template, '*' was mapped to 'main-paths'.

echo "=== Step 4: Importing Patched URL Map ==="
gcloud compute url-maps import "$URL_MAP_NAME" \
  --project="$PROJECT_ID" \
  --source="$TMP_URL_MAP" \
  --global \
  --quiet

echo ""
echo "============================================="
echo "  Live Patch Completed!"
echo "============================================="
echo "New SSL Cert: $NEW_SSL_CERT"
echo "Domains:      $SSL_DOMAINS"
echo "URL Map:      $URL_MAP_NAME"
echo "============================================="
echo "Note: SSL provisioning can take up to 30-60 minutes."
echo "Verify with: gcloud compute ssl-certificates describe $NEW_SSL_CERT --project=$PROJECT_ID --global"
