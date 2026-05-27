# Configuration Variables
PROJECT_ID="rocketpay-gcp-setup"
REGION="asia-south1"
CONNECTION="git_hub_rocketpay"
SERVICE_ACCOUNT="projects/$PROJECT_ID/serviceAccounts/cloudbuild-service-account@$PROJECT_ID.iam.gserviceaccount.com"
BRANCH_PATTERN="^master|g-.*$"
FILENAME="ci/cloudbuild.yaml"

# List of repository suffixes
REPOS=("payment_account" "payment_entities" "payment_gateway" "payment_instrument" "payment_mandate" "payment_order" "payments-and-billing")

for REPO in "${REPOS[@]}"; do
    # Convert underscores to hyphens for the name (e.g., payment_account -> payment-account)
    CLEAN_NAME=$(echo $REPO | tr '_' '-')
    
    NAME="rocketpay-$CLEAN_NAME"
    DESCRIPTION="UdharPayIndia/$REPO"
    REPO_PATH="projects/$PROJECT_ID/locations/$REGION/connections/$CONNECTION/repositories/UdharPayIndia-$REPO"

    echo "Updating trigger for $REPO..."

    # 1. Delete the old trigger (the one without the rocketpay- prefix)
    # Using || true to prevent the script from stopping if the old name doesn't exist
    gcloud builds triggers delete "$NAME" --region="$REGION" --quiet || echo "Old trigger $NAME not found."

    # 2. Create the new trigger with Prefix AND Description
    gcloud alpha builds triggers create repository \
        --name="$NAME" \
        --description="$DESCRIPTION" \
        --repository="$REPO_PATH" \
        --branch-pattern="$BRANCH_PATTERN" \
        --build-config="$FILENAME" \
        --service-account="$SERVICE_ACCOUNT" \
        --region="$REGION"
    
    echo "Created: $NAME with description: $DESCRIPTION"
    echo "----------------------------------------------------"
done