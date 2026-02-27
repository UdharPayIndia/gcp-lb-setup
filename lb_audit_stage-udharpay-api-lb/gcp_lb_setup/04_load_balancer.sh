#!/bin/bash
# ==============================================================================
# 04_load_balancer.sh — Create the External HTTP(S) Load Balancer
# ==============================================================================
# GCP equivalent of the AWS ALB itself.
#
# AWS ALB components → GCP components:
#   ALB                → Static IP + Forwarding Rules + Target Proxies
#   HTTPS:443 Listener → HTTPS Forwarding Rule + Target HTTPS Proxy + SSL Cert
#   HTTP:80  Listener  → HTTP Forwarding Rule + Target HTTP Proxy + Redirect URL Map
#   SSL Certificate    → Google-Managed SSL Certificate
#
# The URL Map (routing rules) was created in 03_rules.sh.
# ==============================================================================

set -euo pipefail

PROJECT_ID="${GCP_PROJECT_ID:?Set GCP_PROJECT_ID env var}"

# Domain(s) for the SSL certificate
SSL_DOMAINS="gcp-staging-api.rocketpay.co.in,gcp-staging-distributor.rocketpay.co.in"

echo "=== Step 1: Reserve a Global Static IP ==="
gcloud compute addresses create stage-lbip-as1-udharpay-api \
  --project="$PROJECT_ID" \
  --global \
  --ip-version=IPV4 \
  --quiet

STATIC_IP=$(gcloud compute addresses describe stage-lbip-as1-udharpay-api \
  --project="$PROJECT_ID" --global --format="value(address)")
echo "Reserved static IP: $STATIC_IP"

echo "=== Step 2: Create Google-Managed SSL Certificate ==="
gcloud compute ssl-certificates create stage-ssl-as1-udharpay-api \
  --project="$PROJECT_ID" \
  --domains="$SSL_DOMAINS" \
  --global \
  --quiet

echo "=== Step 3: Create HTTPS Target Proxy (port 443) ==="
gcloud compute target-https-proxies create stage-targetproxy-as1-udharpay-api-https \
  --project="$PROJECT_ID" \
  --url-map=stage-lb-as1-udharpay-api \
  --ssl-certificates=stage-ssl-as1-udharpay-api \
  --global \
  --quiet

echo "=== Step 4: Create HTTPS Forwarding Rule (port 443) ==="
gcloud compute forwarding-rules create stage-forwardingrule-as1-udharpay-api-https \
  --project="$PROJECT_ID" \
  --address=stage-lbip-as1-udharpay-api \
  --target-https-proxy=stage-targetproxy-as1-udharpay-api-https \
  --ports=443 \
  --global \
  --quiet

echo "=== Step 5: Create HTTP→HTTPS Redirect (port 80) ==="
# Create a redirect-only URL map
gcloud compute url-maps create stage-lb-as1-udharpay-api-redirect \
  --project="$PROJECT_ID" \
  --default-service=stage-bs-as1-payments-and-billing \
  --global \
  --quiet

Update it to redirect all HTTP traffic to HTTPS
gcloud compute url-maps import stage-lb-as1-udharpay-api-redirect \
  --project="$PROJECT_ID" \
  --global \
  --quiet \
  --source=/dev/stdin <<EOF
name: stage-lb-as1-udharpay-api-redirect
defaultUrlRedirect:
  httpsRedirect: true
  redirectResponseCode: MOVED_PERMANENTLY_DEFAULT
EOF

# Create HTTP target proxy
gcloud compute target-http-proxies create stage-targetproxy-as1-udharpay-api-http \
  --project="$PROJECT_ID" \
  --url-map=stage-lb-as1-udharpay-api-redirect \
  --global \
  --quiet

# Create HTTP forwarding rule (port 80)
gcloud compute forwarding-rules create stage-forwardingrule-as1-udharpay-api-http \
  --project="$PROJECT_ID" \
  --address=stage-lbip-as1-udharpay-api \
  --target-http-proxy=stage-targetproxy-as1-udharpay-api-http \
  --ports=80 \
  --global \
  --quiet

echo ""
echo "============================================="
echo "  Load Balancer Setup Complete!"
echo "============================================="
echo "Static IP:    $STATIC_IP"
echo "HTTPS:443  →  stage-lb-as1-udharpay-api"
echo "HTTP:80    →  301 Redirect to HTTPS"
echo ""
echo "── Resource Names ──"
echo "IP:           stage-lbip-as1-udharpay-api"
echo "SSL:          stage-ssl-as1-udharpay-api"
echo "HTTPS Proxy:  stage-targetproxy-as1-udharpay-api-https"
echo "HTTPS Fwd:    stage-forwardingrule-as1-udharpay-api-https"
echo "HTTP Proxy:   stage-targetproxy-as1-udharpay-api-http"
echo "HTTP Fwd:     stage-forwardingrule-as1-udharpay-api-http"
echo "URL Map:      stage-lb-as1-udharpay-api"
echo "Redirect Map: stage-lb-as1-udharpay-api-redirect"
