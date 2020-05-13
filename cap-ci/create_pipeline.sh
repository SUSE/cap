#!/bin/bash

set -e

# NOTE for now, add your cluster's kubeconfig in git@github.com:SUSE/cf-ci-pools.git on branch ${BACKEND}-kube-hosts in unclaimed folder
# Usage example: ./create_pipeline.sh <concourse-target> <pipeline-name>>
# You can configure all the required values in config yamls: cap-pre-release.yaml, cap-release.yaml or your own.

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
    if [[ "$2" == "cap-release" || "$2" == "cap-pre-release" ]]; then
        printf "This will modify the production pipeline: $2. Are you sure you want to proceed?(yes/no): "
        read -r ans
        if [[ "$ans" == "yes" ]]; then
            export PIPELINE=$2
        else
            echo "Operation aborted."
            exit 1
        fi
    else
        if test -f "$2".yaml; then
            export PIPELINE=$2
        else
            echo "$2.yaml doesn't exist."
            usage
            exit 1
        fi
    fi
fi

fly_args=(
    "--target=${target}"
    "set-pipeline"
    "--pipeline=${PIPELINE}"
)

fly "${fly_args[@]}" --config <(gomplate --verbose --datasource config="$PIPELINE".yaml --file pipeline.template)
