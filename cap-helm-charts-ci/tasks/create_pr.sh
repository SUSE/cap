#!/bin/bash

# This script is used to open a PR against this repository:
# https://github.com/suse/kubernetes-charts-suse-com
# It will fetch the bundle specified by CAP_BUNDLE and will update the helm
# charts in the above repo.

set -e

if [ -z "${GIT_USER}"  ]; then
  echo "GIT_USER environment variable not set"
  exit 1
fi

if [ -z "${GIT_MAIL}"  ]; then
  echo "GIT_MAIL environment variable not set"
  exit 1
fi

if [ -z "${GITHUB_PRIVATE_KEY}" ]; then
  echo "GITHUB_PRIVATE_KEY environment variable not set"
  exit 1
fi

if [ -z "$GITHUB_TOKEN"  ]; then
  echo "GITHUB_TOKEN environment variable not set"
  exit 1
fi

if [ -z "${CHART_BUNDLE}" ]; then
  echo "CHART_BUNDLE environment variable not set"
  exit 1
fi

if [ -z "${HELM_CHARTS_REPO}" ]; then
  echo "HELM_CHARTS_REPO environment variable not set"
  exit 1
fi

# Setup git
mkdir -p ~/.ssh
ssh-keyscan -t rsa github.com | tee ~/.ssh/known_hosts | ssh-keygen -lf -
echo -e ${GITHUB_PRIVATE_KEY} | sed -E 's/(-+(BEGIN|END) OPENSSH PRIVATE KEY-+) *| +/\1\n/g' > ~/.ssh/id_ecdsa
chmod 0600 ~/.ssh/id_ecdsa

git config --global user.email "${GIT_MAIL}"
git config --global user.name "${GIT_USER}"

# Remove old charts
rm -rf ${HELM_CHARTS_REPO}/stable/kubecf
rm -rf ${HELM_CHARTS_REPO}/stable/cf-operator

# Recursively untar bundle, kubecf and cf-operator charts.
cap_bundle=$(find ${CHART_BUNDLE} -name "*.tgz" | cut -d "/" -f2)
tar --to-command="tar -C ${HELM_CHARTS_REPO}/stable/ -xzvf -" -xzvf ${CHART_BUNDLE}/*.tgz
product=$(basename "${cap_bundle}" .tgz)

pushd ${HELM_CHARTS_REPO} 

# Open a PR containing new charts.
pr_title="Release ${product}"
pr_description="Publish Helm charts for release ${product} created from ${cap_bundle}."
git pull
git checkout -b ${product}
git add ${CHART_FOLDERS}
git commit -m "Submitting "${product}
hub pull-request --push --message "$(printf "${pr_title}\n\n${pr_description}")" --base master
