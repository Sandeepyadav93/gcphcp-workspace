set -x
export KUBECONFIG=${KUBECONFIG:-}
export GKE_MC_CLUSTER_NAME=${GKE_MC_CLUSTER_NAME:-ps-sandeep-clean}
export METRIC_PROFILE=$(pwd)/kube-burner/metric-profile.yaml
export METRIC_ENDPOINT=$(pwd)/kube-burner/metrics-endpoints.yaml
export UUID="${UUID:-$(uuidgen | tr '[:upper:]' '[:lower:]')}"
export ES_SERVER=${ES_SERVER:-}
export ES_INDEX=${ES_INDEX:-ripsaw-kube-burner}
export PROJECT_ID=$(gcloud config get-value project 2> /dev/null)
export PROM_URL=${PROM_URL:-https://monitoring.googleapis.com/v1/projects/$PROJECT_ID/location/global/prometheus}
export WORKLOAD=${WORKLOAD:-kubelet-density}
export LOCAL_INDEXING=${LOCAL_INDEXING:-false}
export TOKEN=$(gcloud auth print-access-token)

if [[ $WORKLOAD == "kubelet-density-cni" || $WORKLOAD == "kubelet-density" || $WORKLOAD == "cluster-density-k8s" || $WORKLOAD == "hcp-density-gke" ]]; then
    pushd $PWD/kube-burner/$WORKLOAD
    export START_TIME=$(date +"%s")
    kube-burner init --uuid=${UUID} --config $WORKLOAD.yaml --skip-tls-verify --log-level=trace 2>&1 | tee kube-burner-init-$UUID.log
    export END_TIME=$(date +"%s")
    export TOKEN=$(gcloud auth print-access-token)
    kube-burner index --uuid ${UUID} --start $START_TIME --end $END_TIME -e $METRIC_ENDPOINT 2>&1 | tee kube-burner-index-$UUID.log
    popd
else
    echo "$WORKLOAD: Choose a valid workload"
fi
