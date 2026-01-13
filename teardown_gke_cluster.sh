#!/bin/bash
set -e

# --- 1. Environment Variables ---
export CLUSTER_NAME=${CLUSTER_NAME:-ps-sandeep-clean}
export REGION="us-central1"
export NETWORK_NAME="${CLUSTER_NAME}-vpc"
export SUBNET_NAME="${CLUSTER_NAME}-subnet"

echo "🗑️  Starting interactive cleanup for: $CLUSTER_NAME"

# --- 2. GKE Cluster ---
if gcloud container clusters describe "$CLUSTER_NAME" --region "$REGION" >/dev/null 2>&1; then
    echo "--------------------------------------------------------"
    echo "Found GKE Cluster. Preparing for deletion..."
    # Removing --quiet means gcloud will ask: "Do you want to continue (Y/n)?"
    gcloud container clusters delete "$CLUSTER_NAME" --region "$REGION"
else
    echo "⏭️  Cluster '$CLUSTER_NAME' not found. Skipping."
fi

# --- 3. Subnet ---
if gcloud compute networks subnets describe "$SUBNET_NAME" --region "$REGION" >/dev/null 2>&1; then
    echo "--------------------------------------------------------"
    echo "Found Subnet. Preparing for deletion..."
    # Without --quiet, gcloud will list the subnet details and ask for confirmation
    gcloud compute networks subnets delete "$SUBNET_NAME" --region "$REGION"
else
    echo "⏭️  Subnet '$SUBNET_NAME' not found. Skipping."
fi

# --- 4. VPC Network ---
if gcloud compute networks describe "$NETWORK_NAME" >/dev/null 2>&1; then
    echo "--------------------------------------------------------"
    echo "Found Network. Preparing for deletion..."
    # If a resource is still using this network, gcloud will now 
    # print the exact ERROR message here instead of just exiting.
    gcloud compute networks delete "$NETWORK_NAME"
else
    echo "⏭️  Network '$NETWORK_NAME' not found. Skipping."
fi

echo "--------------------------------------------------------"
echo "✨ Cleanup process finished."
