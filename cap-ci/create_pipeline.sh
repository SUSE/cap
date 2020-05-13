#!/bin/bash

set -e

# NOTE for now, add your cluster's kubeconfig in git@github.com:SUSE/cf-ci-pools.git on branch ${BACKEND}-kube-hosts in unclaimed folder
# Usage example: ./create_cap-release_pipeline.sh <concourse-target> <pipeline-name>
# You can configure all the required values in config.yaml.

if ! hash gomplate 2>/dev/null; then
    echo "gomplate missing. Follow the instructions in https://docs.gomplate.ca/installing/ and install it first."
    exit 1
fi

usage() {
    echo "USAGE:"
    echo "$0 <concourse-target> <pipeline-name>"
}

if [[ -z "$1" ]]; then
    echo "Concourse target not provided."
    usage
    exit 1
else
    target=$1
fi

if [[ -z "$2" ]]; then
    echo "Pipeline name not provided."
    usage
    exit 1
else
    export PIPELINE=$2
fi

fly_args=(
    "--target=${target}"
    "set-pipeline"
    "--pipeline=${PIPELINE}"
)

fly "${fly_args[@]}" --config <(gomplate --verbose --datasource config="$PIPELINE".yaml --file pipeline.template)