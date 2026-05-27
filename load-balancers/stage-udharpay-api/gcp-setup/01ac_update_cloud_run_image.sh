#!/bin/bash
# ==============================================================================
# update_cloud_run_image.sh — Update a Cloud Run service with a new image
# ==============================================================================

set -euo pipefail

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <service-name> <new-image-uri>"
    echo "Example: $0 users-verifications gcr.io/my-project/users-verifications:v1.2.3"
    exit 1
fi

SERVICE_NAME=$1
IMAGE_URI=$2

PROJECT_ID="${GCP_PROJECT_ID:?Set GCP_PROJECT_ID env var}"
REGION="asia-south1"

echo "=== Updating Cloud Run Service: ${SERVICE_NAME} ==="
echo "New Image: ${IMAGE_URI}"

gcloud run deploy "$SERVICE_NAME" \
    --project="$PROJECT_ID" \
    --region="$REGION" \
    --image="$IMAGE_URI" \
    --quiet

echo "✓ Added new revision and updated image for ${SERVICE_NAME}."
