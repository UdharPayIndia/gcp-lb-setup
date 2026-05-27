#!/bin/bash
# ==============================================================================
# 05_test_routing.sh — End-to-End Routing Validation Script
# ==============================================================================
# This script tests all major routing rules of the Load Balancer.
# 
# Usage:
#   1. Set the BASE_DOMAIN below.
#   2. Ensure DNS is configured or subdomains are in /etc/hosts pointing to LB.
#   3. Ensure test-docker-compose.yaml is running on the VM.
#   4. Run this script.
# ==============================================================================

# ─── CONFIGURATION ───
# LB_IP is kept here for reference or manual use
LB_IP="REPLACE_WITH_YOUR_LB_IP"  # e.g., 34.120.x.x
BASE_DOMAIN="rocketpay.co.in"
STAGING_SUBDOMAIN="gcp-staging-api.${BASE_DOMAIN}"
DISTRIBUTOR_SUBDOMAIN="gcp-staging-distributor.${BASE_DOMAIN}"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "=== Starting Routing E2E Test ==="
echo "Target LB IP: $LB_IP"
echo "Base Domain:  $BASE_DOMAIN"
echo "---------------------------------"

test_route() {
    local PATH_URL=$1
    local EXPECTED_CONTENT=$2
    local HOST_HEADER=$3
    
    echo -n "Testing Path: $PATH_URL (Host: $HOST_HEADER) ... "
    
    # Use -L to follow the HTTP->HTTPS redirect
    local CMD="curl -s -L https://${HOST_HEADER}${PATH_URL}"
    echo -n "[$CMD] "
    
    RESPONSE=$($CMD)
    
    # Check if the expected content (based on health check responses) is in the output
    if echo "$RESPONSE" | grep -q "$EXPECTED_CONTENT"; then
        echo -e "${GREEN}PASS${NC}"
    else
        echo -e "${RED}FAIL${NC}"
        echo "  Expected Content: $EXPECTED_CONTENT"
        # If we got a response, show a snippet, otherwise indicate connection issue
        if [ -z "$RESPONSE" ]; then
            echo "  Error: No response from Load Balancer."
        else
            echo "  Actual Response Snippet: $(echo "$RESPONSE" | head -n 1)"
        fi
    fi
}

# ─── 1. Host-Based Routing (Distributor) ───
test_route "/" "distributor-app" "$DISTRIBUTOR_SUBDOMAIN" # Assuming still returning typical index or host

# ─── 2. Path-Based Routing (Main Path Matcher) ───

# P100: support-service
test_route "/support-service/" "support-service" "$STAGING_SUBDOMAIN"

# P110: users-and-verifications (Exact Match)
test_route "/account/v2/authenticate" "users-verifications" "$STAGING_SUBDOMAIN"

# P120: account-preference
test_route "/account/" "account-preference" "$STAGING_SUBDOMAIN"

# P140: payments-billing
test_route "/payments-and-billing/" "payments-billing" "$STAGING_SUBDOMAIN"

# P180: udharpay-api
test_route "/v1/merchant/" "udharpay-api" "$STAGING_SUBDOMAIN"

# P200: superkey
test_route "/superkey/" "superkey" "$STAGING_SUBDOMAIN"

# P220: dlt
test_route "/dlt/" "dlt" "$STAGING_SUBDOMAIN"

# P250: rule-engine
test_route "/rule/actuator/health" "UP" "$STAGING_SUBDOMAIN"

# P280: workflow
test_route "/workflow/" "workflow" "$STAGING_SUBDOMAIN" # Adjust expected string to match workflow's health check

# P290: key
test_route "/key/" "key" "$STAGING_SUBDOMAIN"

# P300: key-gateway
test_route "/key-gateway/" "key-gateway" "$STAGING_SUBDOMAIN"

# P320: platform-common
test_route "/book/" "platform-common" "$STAGING_SUBDOMAIN"

# P330: product-order
test_route "/product-order/" "product-order" "$STAGING_SUBDOMAIN"

# P340: lending
test_route "/lending/" "lending" "$STAGING_SUBDOMAIN"

# P350: crm
test_route "/crm/" "crm" "$STAGING_SUBDOMAIN"

# P370: ai-apps
test_route "/support-agent/" "ai-apps" "$STAGING_SUBDOMAIN"

# ─── 3. Default (503) Routing ───
echo -n "Testing Default Route (Unknown Path) ... "
CMD="curl -s -L https://${STAGING_SUBDOMAIN}/non-existent-path"
echo -n "[$CMD] "
RESPONSE=$($CMD)
if echo "$RESPONSE" | grep -q "503 - Api is Not supported"; then
    echo -e "${GREEN}PASS (Correctly served 503)${NC}"
else
    echo -e "${RED}FAIL${NC}"
fi

echo "---------------------------------"
echo "=== 4. HTTP to HTTPS Redirect Test ==="
echo -n "Testing Redirect (HTTP -> HTTPS) ... "
# -I shows headers, we look for 301 and the Location header
REDIRECT_INFO=$(curl -s -I "http://${STAGING_SUBDOMAIN}/")
if echo "$REDIRECT_INFO" | grep -q "HTTP/1.1 301" && echo "$REDIRECT_INFO" | grep -q "Location: https://"; then
    echo -e "${GREEN}PASS (Redirect active)${NC}"
else
    echo -e "${RED}FAIL (No redirect found)${NC}"
    echo "  Response Headers:"
    echo "$REDIRECT_INFO" | sed 's/^/    /'
fi

echo "---------------------------------"
echo "=== E2E Test Complete ==="
