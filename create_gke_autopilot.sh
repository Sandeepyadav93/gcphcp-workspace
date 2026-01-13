#!/bin/bash
set -e

# --- 1. Environment Variables ---
export CLUSTER_NAME=${CLUSTER_NAME:-ps-sandeep-clean}
export REGION="us-central1"
export PROJECT_ID=$(gcloud config get-value project 2> /dev/null)

export NETWORK_NAME="${CLUSTER_NAME}-vpc"
export SUBNET_NAME="${CLUSTER_NAME}-subnet"

# IP Ranges
export PRIMARY_RANGE="10.10.0.0/24"
export POD_RANGE="10.11.0.0/17"
export SERVICE_RANGE="10.12.0.0/22"

echo "🚀 Starting setup for cluster: $CLUSTER_NAME"

# --- 2. Create VPC (if not exists) ---
if gcloud compute networks describe "$NETWORK_NAME" >/dev/null 2>&1; then
    echo "✅ Network '$NETWORK_NAME' already exists. Skipping creation."
else
    echo "Creating network: $NETWORK_NAME..."
    gcloud compute networks create "$NETWORK_NAME" --subnet-mode=custom --mtu=1460
fi

# --- 3. Create Subnet (if not exists) ---
if gcloud compute networks subnets describe "$SUBNET_NAME" --region="$REGION" >/dev/null 2>&1; then
    echo "✅ Subnet '$SUBNET_NAME' already exists. Skipping creation."
else
    echo "Creating subnet: $SUBNET_NAME..."
    gcloud compute networks subnets create "$SUBNET_NAME" \
        --network="$NETWORK_NAME" \
        --region="$REGION" \
        --range="$PRIMARY_RANGE" \
        --enable-private-ip-google-access \
        --secondary-range="pods-range=$POD_RANGE,services-range=$SERVICE_RANGE"
fi

# --- 4. Create GKE Autopilot Cluster ---
echo "Spawning GKE Autopilot Cluster... (This may take 5-10 minutes)"
gcloud beta container clusters create-auto "$CLUSTER_NAME" \
    --region "$REGION" \
    --network "$NETWORK_NAME" \
    --subnetwork "$SUBNET_NAME" \
    --cluster-secondary-range-name="pods-range" \
    --services-secondary-range-name="services-range" \
    --release-channel="regular" \
    --monitoring=SYSTEM,API_SERVER,CONTROLLER_MANAGER,SCHEDULER,HPA,STATEFULSET,DEPLOYMENT,DAEMONSET,POD,STORAGE,CADVISOR,KUBELET

echo "✅ Deployment Successful!"
