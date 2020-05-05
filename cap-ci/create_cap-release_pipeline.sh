#!/bin/bash
set -x

# NOTE for now, add your cluster's kubeconfig in git@github.com:SUSE/cf-ci-pools.git on branch ${BACKEND}-kube-hosts in unclaimed folder
# Usage example: PIPELINE=name-demo-release BACKEND='backend: [ caasp4, eks ]' OPTIONS='options: [ sa ]' EIRINI='eirini: [ diego ]' ./create_cap-release_pipeline.sh

export PIPELINE="${PIPELINE-cap-release}"

rm "$PIPELINE".yaml 2>/dev/null || true
export BACKEND="${BACKEND:-backend: [ caasp4, aks, gke, eks ]}"
export OPTIONS="${OPTIONS:-options: [ sa, ha, all ]}"
export EIRINI="${EIRINI:-eirini: [ diego, eirini ]}"

export BRAIN_VERBOSE="${BRAIN_VERBOSE:-false}"
export BRAIN_INORDER="${BRAIN_INORDER:-false}"
export BRAIN_INCLUDE="${BRAIN_INCLUDE:-}"
export BRAIN_EXCLUDE="${BRAIN_EXCLUDE:-}"

gomplate -d 'BACKEND=env:///BACKEND?type=application/yaml' \
         -d 'OPTIONS=env:///OPTIONS?type=application/yaml' \
         -d 'EIRINI=env:///EIRINI?type=application/yaml' \
         -d 'BRAIN_VERBOSE=env:///BRAIN_VERBOSE' \
         -d 'BRAIN_INORDER=env:///BRAIN_INORDER' \
         -d 'BRAIN_INCLUDE=env:///BRAIN_INCLUDE' \
         -d 'BRAIN_EXCLUDE=env:///BRAIN_EXCLUDE' \
         -d config.yaml \
         -f pipeline.template > "$PIPELINE".yaml

fly -t concourse.suse.dev sp -c "$PIPELINE".yaml -p "$PIPELINE"
