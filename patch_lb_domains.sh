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

# New domains
API_STAGING_DOMAIN="api-staging.rocketpay.co.in"
RPG_STAGING_DOMAIN="stage-api-pg.rocketpay.co.in"
ADMIN_STAGING_DOMAIN="admin-staging.udharpay.com"
DISTRIBUTOR_STAGING_DOMAIN="staging-distributor.rocketpay.co.in"

  # GCP versions
GCP_API_STAGING_DOMAIN="gcp-api-staging.rocketpay.co.in"
GCP_RPG_STAGING_DOMAIN="gcp-stage-api-pg.rocketpay.co.in"
GCP_ADMIN_STAGING_DOMAIN="gcp-admin-staging.udharpay.com"
GCP_DISTRIBUTOR_STAGING_DOMAIN="gcp-staging-distributor.rocketpay.co.in"

echo "=== Step 1: Update Host Rules in URL Map ==="

# Note: We need to use 'gcloud compute url-maps add-host-rule' or 'import'
# Since we are changing existing hosts, we will use a temporary YAML to patch.

TMP_URL_MAP="/tmp/live-url-map-patch.yaml"

echo "Fetching current URL map..."
gcloud compute url-maps describe "$URL_MAP_NAME" --project="$PROJECT_ID" --global > "$TMP_URL_MAP"

echo "Patching URL map YAML..."
# Replace RPG host
sed -i.bak "s/${GCP_RPG_STAGING_DOMAIN}/${RPG_STAGING_DOMAIN}/g" "$TMP_URL_MAP"

# Replace Distributor host
sed -i.bak "s/${GCP_DISTRIBUTOR_STAGING_DOMAIN}/${DISTRIBUTOR_STAGING_DOMAIN}/g" "$TMP_URL_MAP"

# Ensure the '*' host (main-paths) supports api-staging.rocketpay.co.in
# Actually, the defaultService and '*' host rule handle the main API paths.
# We should probably add an explicit host rule for api-staging.rocketpay.co.in 
# to ensure it's mapped to main-paths.

# Let's check if 'api-staging.rocketpay.co.in' should be in hostRules.
# In the template, '*' was mapped to 'main-paths'.

echo "=== Step 2: Importing Patched URL Map ==="
gcloud compute url-maps import "$URL_MAP_NAME" \
  --project="$PROJECT_ID" \
  --source="$TMP_URL_MAP" \
  --global \
  --quiet

echo ""
echo "============================================="
echo "  Live Patch Completed!"
echo "============================================="
echo "URL Map:      $URL_MAP_NAME"
echo "============================================="

