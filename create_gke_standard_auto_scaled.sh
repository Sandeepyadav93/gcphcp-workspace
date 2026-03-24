#!/bin/bash
set -e

# --- 1. Environment Variables ---
export CLUSTER_NAME=${CLUSTER_NAME:-ps-sandeep-clean}
export REGION="us-central1"
export PROJECT_ID=$(gcloud config get-value project 2> /dev/null)

export NETWORK_NAME="${CLUSTER_NAME}-vpc"
export SUBNET_NAME="${CLUSTER_NAME}-subnet"

# In regional clusters, min/max are nodes PER ZONE (e.g., max 10 x 3 zones = 30 nodes total)
export MIN_NODES_PER_ZONE=${MIN_NODES_PER_ZONE:-8}
export MAX_NODES_PER_ZONE=${MAX_NODES_PER_ZONE:-20}
export WORKER_TYPE=${WORKER_TYPE:-e2-standard-16}
export MAX_PODS_PER_WORKER=${MAX_PODS_PER_WORKER:-250}

# IP Ranges
export PRIMARY_RANGE="10.10.0.0/24"
export POD_RANGE="172.16.0.0/16"
export SERVICE_RANGE="172.17.0.0/17"

echo "🚀 Starting setup for GKE Standard Cluster with Autoscaling: $CLUSTER_NAME"

# --- 2. Create VPC (if not exists) ---
if ! gcloud compute networks describe "$NETWORK_NAME" >/dev/null 2>&1; then
    echo "Creating network: $NETWORK_NAME..."
    gcloud compute networks create "$NETWORK_NAME" --subnet-mode=custom --mtu=1460
fi

# --- 3. Create Subnet (if not exists) ---
if ! gcloud compute networks subnets describe "$SUBNET_NAME" --region="$REGION" >/dev/null 2>&1; then
    echo "Creating subnet: $SUBNET_NAME..."
    gcloud compute networks subnets create "$SUBNET_NAME" \
        --network="$NETWORK_NAME" \
        --region="$REGION" \
        --range="$PRIMARY_RANGE" \
        --enable-private-ip-google-access \
        --secondary-range="pods-range=$POD_RANGE,services-range=$SERVICE_RANGE"
fi

# --- 4. Create GKE Standard Regional Cluster with Autoscaling ---
echo "Spawning GKE Standard Cluster with Autoscaling... (This may take 10-15 minutes)"
gcloud container clusters create "$CLUSTER_NAME" \
    --region "$REGION" \
    --enable-autoscaling \
    --min-nodes "$MIN_NODES_PER_ZONE" \
    --max-nodes "$MAX_NODES_PER_ZONE" \
    --machine-type "$WORKER_TYPE" \
    --enable-ip-alias \
    --enable-dataplane-v2 \
    --max-pods-per-node "$MAX_PODS_PER_WORKER" \
    --default-max-pods-per-node "$MAX_PODS_PER_WORKER" \
    --network "$NETWORK_NAME" \
    --subnetwork "$SUBNET_NAME" \
    --cluster-secondary-range-name="pods-range" \
    --services-secondary-range-name="services-range" \
    --release-channel="regular" \
    --autoscaling-profile balanced \
    --labels="billing-tag=$CLUSTER_NAME" \
    --monitoring=SYSTEM,API_SERVER,CONTROLLER_MANAGER,SCHEDULER,HPA,STATEFULSET,DEPLOYMENT,DAEMONSET,POD,STORAGE,CADVISOR,KUBELET

echo "✅ Deployment Successful!"
