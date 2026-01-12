set -x
export KUBECONFIG=${KUBECONFIG:-}
export GKE_MC_CLUSTER_NAME=${GKE_MC_CLUSTER_NAME:-}
export METRIC_PROFILE=$(pwd)/kube-burner/metric-profile.yaml
export UUID="${UUID:-$(uuidgen | tr '[:upper:]' '[:lower:]')}"
export ES_SERVER=${ES_SERVER:-}
export ES_INDEX=${ES_INDEX:-ripsaw-kube-burner}
export PROM_URL=${PROM_URL:-https://monitoring.googleapis.com/v1/projects/$PROJECT/location/global/prometheus}
export TOKEN=${TOKEN:-}
export WORKLOAD=${WORKLOAD:-kubelet-density}

if [[ $WORKLOAD == "kubelet-density-cni" || $WORKLOAD == "kubelet-density" || $WORKLOAD == "cluster-density-k8s" || $WORKLOAD == "hcp-density-aks" ]]; then
    pushd $PWD/kube-burner/$WORKLOADpushd $PWD/kube-burner/$WORKLOAD
    export START_TIME=$(date +"%s")
    kube-burner init --config $WORKLOAD.yaml --prometheus-url="$PROM_URL" --token "$TOKEN" --metrics-profile "$METRIC_PROFILE" --skip-tls-verify
    export END_TIME=$(date +"%s")
    kube-burner index --uuid=${UUID} --prometheus-url=${PROM_URL} --token ${TOKEN} --start=$START_TIME --end=$END_TIME --metrics-profile ${METRIC_PROFILE} --skip-tls-verify --es-server=${ES_SERVER} --es-index=${ES_INDEX}
    kubectl delete ns -l kube-burner-job=${WORKLOAD}
    popd
else
    echo "$WORKLOAD: Choose a valid workload"
fi
