#!/bin/bash
# ==============================================================================
# 01aa_create_secrets.sh — Create Secret Manager secrets from local files
# ==============================================================================
# Usage: ./01aa_create_secrets.sh <SECRET_NAME> <FILE_PATH>
# Example: ./01aa_create_secrets.sh rp-stage-secret-users-verifications-config-json5 ./config.json5
# Example: ./01aa_create_secrets.sh rp-stage-secret-users-verifications-pm2-ecosystem-config ./ecosystem.config.json
# ==============================================================================

set -euo pipefail

PROJECT_ID="${GCP_PROJECT_ID:?Set GCP_PROJECT_ID env var}"

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <SECRET_NAME> <FILE_PATH>"
    echo "Example: $0 rp-stage-secret-users-verifications-config-json5 ./config.json5"
    exit 1
fi

SECRET_NAME=$1
FILE_PATH=$2

if [ ! -f "$FILE_PATH" ]; then
    echo "Error: File '$FILE_PATH' does not exist."
    exit 1
fi

echo "=== Creating Secret: $SECRET_NAME ==="

# Check if secret already exists
if gcloud secrets describe "$SECRET_NAME" --project="$PROJECT_ID" >/dev/null 2>&1; then
    echo "Secret '$SECRET_NAME' already exists. Adding a new version from $FILE_PATH..."
    gcloud secrets versions add "$SECRET_NAME" --data-file="$FILE_PATH" --project="$PROJECT_ID"
else
    echo "Creating new secret '$SECRET_NAME' from $FILE_PATH..."
    gcloud secrets create "$SECRET_NAME" --data-file="$FILE_PATH" --project="$PROJECT_ID"
fi

# Allow the Compute Engine service account to access the secret
SERVICE_ACCOUNT="581889672100-compute@developer.gserviceaccount.com"
echo "Granting Secret Accessor role to $SERVICE_ACCOUNT for $SECRET_NAME..."
gcloud secrets add-iam-policy-binding "$SECRET_NAME" \
    --member="serviceAccount:$SERVICE_ACCOUNT" \
    --role="roles/secretmanager.secretAccessor" \
    --project="$PROJECT_ID" \
    --quiet

echo "✓ Secret '$SECRET_NAME' is ready."
echo ""
