#!/bin/bash
# ==============================================================================
# 04_load_balancer_no_ssl.sh — Create the External HTTP Load Balancer (No SSL)
# ==============================================================================
# This script sets up a Load Balancer that exposes the backend services on Port 80
# WITHOUT any SSL/HTTPS requirement.
#
# It reuses the URL Map 'stage-lb-as1-udharpay-api' (created in 03_rules.sh)
# which contains all 25+ routing rules for the backend services.
# ==============================================================================

set -euo pipefail

PROJECT_ID="${GCP_PROJECT_ID:?Set GCP_PROJECT_ID env var}"

echo "=== Step 1: Reserve a Global Static IP ==="
# Using a specific name to avoid collision with the SSL-enabled LB IP
IP_NAME="stage-lbip-as1-udharpay-api-no-ssl"
gcloud compute addresses create "$IP_NAME" \
  --project="$PROJECT_ID" \
  --global \
  --ip-version=IPV4 \
  --quiet || echo "Static IP $IP_NAME already exists."

STATIC_IP=$(gcloud compute addresses describe "$IP_NAME" \
  --project="$PROJECT_ID" --global --format="value(address)")
echo "Reserved static IP: $STATIC_IP"

echo "=== Step 2: Create HTTP Target Proxy (Direct to URL Map) ==="
# We use the main URL Map created in 03_rules.sh
URL_MAP="stage-lb-as1-udharpay-api"
PROXY_NAME="stage-targetproxy-as1-udharpay-api-http-no-ssl"

# Check if URL map exists
if ! gcloud compute url-maps describe "$URL_MAP" --project="$PROJECT_ID" --global >/dev/null 2>&1; then
  echo "Error: URL Map '$URL_MAP' not found! Run 03_rules.sh first."
  exit 1
fi

gcloud compute target-http-proxies create "$PROXY_NAME" \
  --project="$PROJECT_ID" \
  --url-map="$URL_MAP" \
  --global \
  --quiet || echo "Target HTTP Proxy $PROXY_NAME already exists."

echo "=== Step 3: Create HTTP Forwarding Rule (Port 80) ==="
FWD_RULE_NAME="stage-forwardingrule-as1-udharpay-api-http-no-ssl"
gcloud compute forwarding-rules create "$FWD_RULE_NAME" \
  --project="$PROJECT_ID" \
  --address="$IP_NAME" \
  --target-http-proxy="$PROXY_NAME" \
  --ports=80 \
  --global \
  --quiet || echo "Forwarding Rule $FWD_RULE_NAME already exists."

echo ""
echo "============================================="
echo "  HTTP Load Balancer (No-SSL) Setup Complete!"
echo "============================================="
echo "Static IP:    $STATIC_IP"
echo "Port 80    →  $URL_MAP (25+ Backend Services)"
echo ""
echo "── Resource Names ──"
echo "IP Address:   $IP_NAME"
echo "HTTP Proxy:   $PROXY_NAME"
echo "Forwarding:   $FWD_RULE_NAME"
echo "URL Map:      $URL_MAP"
echo "============================================="
echo "Note: You can now access your services at http://$STATIC_IP/..."
