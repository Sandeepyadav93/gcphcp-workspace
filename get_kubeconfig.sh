#!/bin/bash
set -e

# --- 1. Environment Variables ---
export CLUSTER_NAME=${CLUSTER_NAME:-ps-sandeep-clean}
export REGION="us-central1"
export PROJECT_ID=$(gcloud config get-value project 2> /dev/null)


gcloud container clusters get-credentials $CLUSTER_NAME --region $REGION --project $PROJECT_ID
