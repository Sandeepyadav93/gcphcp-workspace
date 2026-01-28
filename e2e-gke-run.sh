set -x
export KUBECONFIG=${KUBECONFIG:-}
export GKE_MC_CLUSTER_NAME=${GKE_MC_CLUSTER_NAME:-ps-sandeep-clean}
export METRIC_PROFILE=$(pwd)/kube-burner/metric-profile.yaml
export UUID="${UUID:-$(uuidgen | tr '[:upper:]' '[:lower:]')}"
export ES_SERVER=${ES_SERVER:-}
export ES_INDEX=${ES_INDEX:-ripsaw-kube-burner}
export PROJECT_ID=$(gcloud config get-value project 2> /dev/null)
export PROM_URL=${PROM_URL:-https://monitoring.googleapis.com/v1/projects/$PROJECT_ID/location/global/prometheus}
export TOKEN=$(gcloud auth print-access-token)
export WORKLOAD=${WORKLOAD:-kubelet-density}
export LOCAL_INDEXING=${LOCAL_INDEXING:-false}

if [[ $WORKLOAD == "kubelet-density-cni" || $WORKLOAD == "kubelet-density" || $WORKLOAD == "cluster-density-k8s" || $WORKLOAD == "hcp-density-gke" ]]; then
    pushd $PWD/kube-burner/$WORKLOAD
    kube-burner init --uuid=${UUID} --config $WORKLOAD.yaml --skip-tls-verify
    popd
else
    echo "$WORKLOAD: Choose a valid workload"
fi
