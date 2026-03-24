#!/bin/bash
set -e

# --- 1. Environment Variables ---
export CLUSTER_NAME=${CLUSTER_NAME:-ps-sandeep-clean}
export REGION="us-central1"
export ZONE="us-central1-a"  # <--- Added for Zonal
export PROJECT_ID=$(gcloud config get-value project 2> /dev/null)

export NETWORK_NAME="${CLUSTER_NAME}-vpc"
export SUBNET_NAME="${CLUSTER_NAME}-subnet"

# In Zonal, this is the TOTAL number of nodes in the cluster
export NUM_WORKER_NODES=${NUM_WORKER_NODES:-1} 
export WORKER_TYPE=${WORKER_TYPE:-n2-standard-4}
export MAX_PODS_PER_WORKER=${MAX_PODS_PER_WORKER:-250}

# IP Ranges
export PRIMARY_RANGE="10.10.0.0/24"
export POD_RANGE="172.16.0.0/16"
export SERVICE_RANGE="172.17.0.0/17"

echo "🚀 Starting setup for GKE Zonal Cluster: $CLUSTER_NAME in $ZONE"

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

# --- 4. Create GKE Zonal Cluster ---
echo "Spawning GKE Zonal Cluster..."
gcloud container clusters create "$CLUSTER_NAME" \
    --zone "$ZONE" \
    --num-nodes "$NUM_WORKER_NODES" \
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
    --monitoring=SYSTEM,API_SERVER,CONTROLLER_MANAGER,SCHEDULER,HPA,STATEFULSET,DEPLOYMENT,DAEMONSET,POD,STORAGE,CADVISOR,KUBELET

echo "✅ Deployment Successful!"
