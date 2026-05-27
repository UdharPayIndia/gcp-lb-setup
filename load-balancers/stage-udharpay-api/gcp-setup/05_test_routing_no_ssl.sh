#!/bin/bash
# ==============================================================================
# 05_test_routing_no_ssl.sh — E2E Routing Validation for No-SSL LB
# ==============================================================================
# This script tests the routing rules using pure HTTP (No SSL).
#
# Usage:
#   1. Set the LB_IP below (the IP from 04_load_balancer_no_ssl.sh).
#   2. Run this script.
# ==============================================================================

PROJECT_ID="${GCP_PROJECT_ID:?Set GCP_PROJECT_ID env var}"
LB_IP=$(gcloud compute addresses describe stage-lbip-as1-udharpay-api-no-ssl --project="$PROJECT_ID" --global --format="value(address)" 2>/dev/null || echo "REPLACE_WITH_LB_IP")

BASE_DOMAIN="rocketpay.co.in"
STAGING_SUBDOMAIN="gcp-staging-api.${BASE_DOMAIN}"
DISTRIBUTOR_SUBDOMAIN="gcp-staging-distributor.${BASE_DOMAIN}"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "=== Starting Routing E2E Test (HTTP ONLY) ==="
echo "Target LB IP: $LB_IP"
echo "Host Header:  $STAGING_SUBDOMAIN"
echo "---------------------------------"

test_route() {
    local PATH_URL=$1
    local EXPECTED_CONTENT=$2
    local HOST_HEADER=$3
    
    echo -n "Testing Path: $PATH_URL ... "
    
    # We use --resolve to map the subdomain to the LB IP directly for the test
    # This avoids needing DNS or /etc/hosts entries.
    local CMD="curl -s --resolve ${HOST_HEADER}:80:${LB_IP} http://${HOST_HEADER}${PATH_URL}"
    # echo -n "[$CMD] "
    
    RESPONSE=$($CMD)
    
    if echo "$RESPONSE" | grep -q "$EXPECTED_CONTENT"; then
        echo -e "${GREEN}PASS${NC}"
    else
        echo -e "${RED}FAIL${NC}"
        echo "  Expected Content: $EXPECTED_CONTENT"
        if [ -z "$RESPONSE" ]; then
            echo "  Error: No response from Load Balancer."
        else
            echo "  Actual Response Snippet: $(echo "$RESPONSE" | head -n 1)"
        fi
    fi
}

# ─── 1. Host-Based Routing (Distributor) ───
test_route "/" "distributor-app" "$DISTRIBUTOR_SUBDOMAIN"

# ─── 2. Path-Based Routing (Main Path Matcher) ───
test_route "/support-service/" "support-service" "$STAGING_SUBDOMAIN"
test_route "/account/v2/authenticate" "users-verifications" "$STAGING_SUBDOMAIN"
test_route "/v1/merchant/" "udharpay-api" "$STAGING_SUBDOMAIN"
test_route "/payments-and-billing/" "payments-billing" "$STAGING_SUBDOMAIN"

# ─── 3. Default (503) Routing ───
echo -n "Testing Default Route (Unknown Path) ... "
CMD="curl -s --resolve ${STAGING_SUBDOMAIN}:80:${LB_IP} http://${STAGING_SUBDOMAIN}/non-existent-path"
RESPONSE=$($CMD)
if echo "$RESPONSE" | grep -q "503 - Api is Not supported"; then
    echo -e "${GREEN}PASS (Correctly served 503)${NC}"
else
    echo -e "${RED}FAIL${NC}"
fi

echo "---------------------------------"
echo "=== E2E Test Complete ==="
echo "Note: If tests fail, ensure the backend services are healthy and the VM is running."
