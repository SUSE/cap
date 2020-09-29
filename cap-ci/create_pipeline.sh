#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

# NOTE for now, add your cluster's kubeconfig in 
# git@github.com:SUSE/cf-ci-pools.git in the ${BACKEND}-kube-hosts branch under
# the unclaimed folder.
# Usage example: ./create_pipeline.sh <concourse-target> <pipeline-name>>
# You can configure all the required values in config yamls:
# cap-pre-release.yaml, cap-release.yaml or your own.

if ! hash gomplate 2>/dev/null; then
  >&2 echo "ERROR: 'gomplate' missing. https://docs.gomplate.ca/installing/."
  exit 1
fi

if ! hash jq 2>/dev/null; then
  >&2 echo "ERROR: 'jq' missing. Install it first."
  exit 1
fi

if ! hash fly 2>/dev/null; then
  >&2 echo "ERROR: 'fly' missing. Install it first."
  exit 1
fi

usage() {
  >&2 echo "USAGE:"
  >&2 echo "$0 CONCOURSE_TARGET PIPELINE [PIPELINE_FILE]"
}

if [[ -z "$1" ]]; then
  >&2 echo "ERROR: Concourse target not provided."
  usage
  exit 1
else
  target=$1
fi

if [[ -z "$2" ]]; then
  >&2 echo "ERROR: Pipeline name not provided."
  usage
  exit 1
else
  export PIPELINE=${2}
  if [[ "${PIPELINE}" == "cap-release" || "${PIPELINE}" == "cap-pre-release" ]]; then
    echo "WARNING! This will modify the production pipeline: ${PIPELINE}."
    printf "Are you sure you want to proceed? (yes/no): "
    read -r answer
    if [[ "${answer}" != "y" && "${answer}" != "yes" ]]; then
      >&2 echo "ERROR: Operation aborted."
      exit 1
    fi
  fi

  if test -f "${PIPELINE}".yaml; then
    pipeline_config=${PIPELINE}.yaml
  else
    >&2 echo "ERROR: Config file ${PIPELINE}.yaml doesn't exist."
    usage
    exit 1
  fi
fi

fly_args=(
  "--target=${target}"
  "set-pipeline"
  "--pipeline=${PIPELINE}"
)

# Space-separated paths to template files and directories which contain template
# files.
template_paths="scripts jobs common"
templates=$(find ${template_paths} -type f -exec echo "--template="{} \;)
pipeline_file=${3:-pipeline.yaml.tmpl}

# Determine if the pipeline being pushed is a new pipeline.
existing_pipeline_job_count=$(
  fly \
    --target ${target} \
    get-pipeline \
    --pipeline ${PIPELINE} \
    --json \
    | jq '.jobs | length')
if [[ ${existing_pipeline_job_count} -gt 0 ]]; then
  pipeline_already_existed=true
else
  pipeline_already_existed=false
fi

# Push a new pipeline, or update an existing one.
fly "${fly_args[@]}" --config <(
  gomplate \
    --verbose \
    --datasource config="${pipeline_config}" \
    ${templates} \
    --file "${pipeline_file}")

# If the pipeline being pushed was a *new* pipeline, pause all the 'initial'
# jobs (jobs without 'passed:' dependencies).
# Important caveat: if a pipeline is updated to add new targets, the new initial
# jobs will *not* be paused.
if ! ${pipeline_already_existed}; then
  jobs_without_dependencies_names=$(
    fly \
      ${target:+"--target=${target}"} \
      get-pipeline \
      --json \
      --pipeline "${PIPELINE}" \
      | jq -r '.jobs - [.jobs[] | select(.plan[] | .passed)] | .[].name')
  for job_name in ${jobs_without_dependencies_names}; do
    fly ${target:+"--target=${target}"} pause-job -j "${PIPELINE}/${job_name}"
  done
  fly ${target:+"--target=${target}"} unpause-pipeline --pipeline="${PIPELINE}"
fi
