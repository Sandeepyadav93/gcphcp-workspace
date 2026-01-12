set -e

# Environment Variables
export CLUSTER_NAME=${CLUSTER_NAME:-ps-sandeep-1}
export REGION=${REGION:-us-central1}
export RELEASE_CHANNEL=${RELEASE_CHANNEL:-regular}
export NETWORK_NAME=${NETWORK_NAME:-sandyada-gcp-2kpsd-network}
export SUBNET_NAME=${SUBNET_NAME:-sandyada-gcp-2kpsd-master-subnet}

# Fetches the project ID currently set in your gcloud config
export PROJECT_NAME=$(gcloud config get-value project 2> /dev/null)

# Fallback: if no project is set, the script will exit with an error
if [ -z "$PROJECT_NAME" ]; then
  echo "Error: No active Google Cloud project found in 'gcloud config'. Please run 'gcloud config set project [PROJECT_ID]'"
  exit 1
fi

# GKE Autopilot Creation with Control Plane Monitoring
gcloud beta container --project "${PROJECT_NAME}" clusters create-auto "${CLUSTER_NAME}" \
    --region "${REGION}" \
    --release-channel "${RELEASE_CHANNEL}" \
    --network "projects/${PROJECT_NAME}/global/networks/${NETWORK_NAME}" \
    --subnetwork "projects/${PROJECT_NAME}/regions/${REGION}/subnetworks/${SUBNET_NAME}" \
    --cluster-ipv4-cidr "/17" \
    --binauthz-evaluation-mode=DISABLED \
    --enable-ip-access \
    --no-enable-google-cloud-access \
    --monitoring=SYSTEM,API_SERVER,CONTROLLER_MANAGER,SCHEDULER,HPA,STATEFULSET,DEPLOYMENT,DAEMONSET,POD,STORAGE,CADVISOR,KUBELET
