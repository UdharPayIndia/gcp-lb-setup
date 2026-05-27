#!/bin/bash

# --- Configuration ---
SRC_HOST="stage-vm-as1-staging-apps-and-services"
SRC_PORT="2222"
SRC_USER="ubuntu"

DEST_HOST="stage-vm-as1-staging-apps-and-services-arm64"
DEST_PORT="4222"
DEST_USER="ubuntu"

# List of directories and files to move
TARGETS=(
    "api-service" "book" "crm" "dlt" "gcp-deploy.sh" 
    "key-management-service" "key_gateway" "kill-services.sh" 
    "launch-services.sh" "party_service" "payment_account" 
    "payment_gateway" "payment_instrument" "payment_mandate" 
    "payment_order" "payments-and-billing" "product_order" 
    "rule" "setup-jre.sh" "udharpay-admin" 
    "users-and-verifications" "workflow"
)

echo "----------------------------------------------------------"
echo "Starting migration from Port $SRC_PORT to Port $DEST_PORT"
echo "----------------------------------------------------------"

# 1. Create a tarball on the source, pipe it locally, and extract on destination
# We use 'c' for create, 'z' for compress (faster over network), and 'f -' for stdout/stdin
ssh -p $SRC_PORT ${SRC_USER}@${SRC_HOST} "tar -czf - ${TARGETS[@]}" | \
ssh -p $DEST_PORT ${DEST_USER}@${DEST_HOST} "tar -xzf - -C ~/"

if [ $? -eq 0 ]; then
    echo "----------------------------------------------------------"
    echo "SUCCESS: All files have been transferred."
    echo "Check destination: ssh -p $DEST_PORT ${DEST_USER}@${DEST_HOST} 'ls -la'"
    echo "----------------------------------------------------------"
else
    echo "----------------------------------------------------------"
    echo "ERROR: Migration failed. Check your SSH keys and connection."
    echo "----------------------------------------------------------"
fi
