#!/bin/bash

# Configuration
LB_NAME="stage-rpg-lb"
REGION="ap-south-1"
BASE_DIR="aws-setup-details"

# Create Directory Structure
mkdir -p "$BASE_DIR/load_balancer/attributes"
mkdir -p "$BASE_DIR/listeners/rules"
mkdir -p "$BASE_DIR/target_groups/attributes"
mkdir -p "$BASE_DIR/target_groups/health"

echo "### Extracting data for $LB_NAME into directory: $BASE_DIR ###"

# 1. Get Load Balancer ARN
LB_ARN=$(aws elbv2 describe-load-balancers --names "$LB_NAME" --region "$REGION" --query 'LoadBalancers[0].LoadBalancerArn' --output text)

if [ -z "$LB_ARN" ] || [ "$LB_ARN" == "None" ]; then
    echo "Error: Could not find Load Balancer with name $LB_NAME"
    exit 1
fi

# --- Load Balancer Core & Attributes ---
echo "Processing Load Balancer Core Details..."
aws elbv2 describe-load-balancers --load-balancer-arns "$LB_ARN" --region "$REGION" --output json > "$BASE_DIR/load_balancer/main_config.json"
aws elbv2 describe-load-balancer-attributes --load-balancer-arn "$LB_ARN" --region "$REGION" --output json > "$BASE_DIR/load_balancer/attributes/lb_attributes.json"

# --- Listeners & Rules ---
echo "Processing Listeners and Rules..."
LISTENER_ARNS=$(aws elbv2 describe-listeners --load-balancer-arn "$LB_ARN" --region "$REGION" --query 'Listeners[*].ListenerArn' --output text)

for LISTENER_ARN in $LISTENER_ARNS; do
    # Create a safe filename from ARN
    L_ID=$(echo "$LISTENER_ARN" | awk -F'/' '{print $NF}')
    aws elbv2 describe-listeners --listener-arns "$LISTENER_ARN" --region "$REGION" --output json > "$BASE_DIR/listeners/listener_$L_ID.json"
    aws elbv2 describe-rules --listener-arn "$LISTENER_ARN" --region "$REGION" --output json > "$BASE_DIR/listeners/rules/rules_$L_ID.json"
done

# --- Target Groups ---
echo "Processing Target Groups..."
TG_ARNS=$(aws elbv2 describe-target-groups --load-balancer-arn "$LB_ARN" --region "$REGION" --query 'TargetGroups[*].TargetGroupArn' --output text)

for TG_ARN in $TG_ARNS; do
    TG_NAME=$(aws elbv2 describe-target-groups --target-group-arns "$TG_ARN" --region "$REGION" --query 'TargetGroups[0].TargetGroupName' --output text)
    
    # Save TG Main Config
    aws elbv2 describe-target-groups --target-group-arns "$TG_ARN" --region "$REGION" --output json > "$BASE_DIR/target_groups/${TG_NAME}_config.json"
    
    # Save TG Attributes
    aws elbv2 describe-target-group-attributes --target-group-arn "$TG_ARN" --region "$REGION" --output json > "$BASE_DIR/target_groups/attributes/${TG_NAME}_attrs.json"
    
    # Save TG Health
    aws elbv2 describe-target-health --target-group-arn "$TG_ARN" --region "$REGION" --output json > "$BASE_DIR/target_groups/health/${TG_NAME}_health.json"
done

echo "------------------------------------------------------------"
echo "Extraction Complete! Find your files in: $BASE_DIR"
echo "Structure:"
ls -R "$BASE_DIR"
