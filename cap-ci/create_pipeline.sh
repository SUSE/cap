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
    echo "$0 CONCOURSE_TARGET PIPELINE [PIPELINE_FILE]"
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
    export PIPELINE=${2}
    if [[ "${PIPELINE}" == "cap-release" || "${PIPELINE}" == "cap-pre-release" ]]; then
        printf "This will modify the production pipeline: ${PIPELINE}. Are you sure you want to proceed?(yes/no): "
        read -r ans
        if [[ "$ans" != "y" && "$ans" != "yes" ]]; then
            echo "Operation aborted."
            exit 1
        fi
    fi
    if test -f "${PIPELINE}".yaml.tmpl; then
        pipeline_config=${PIPELINE}.yaml.tmpl
    else
        echo "Config file ${PIPELINE}.yaml.tmpl doesn't exist."
        usage
        exit 1
    fi
    
fi

fly_args=(
    "--target=${target}"
    "set-pipeline"
    "--pipeline=${PIPELINE}"
)

# space-separated paths to template files and directories which contain template files
template_paths="${pipeline_config} scripts jobs common"
templates=$(find ${template_paths} -type f -exec echo "--template="{} \;)
pipeline_file=${3:-pipeline.yaml.tmpl}
fly "${fly_args[@]}" --config <(gomplate --verbose ${templates} --file "${pipeline_file}")
