#!/bin/bash

set -eux

# Make sure that all required variabels are set
: "${S3_BASE_URL}"
: "${OBS_USERNAME}"
: "${OBS_PASSWORD}"
: "${OBS_STEMCELL_PROJECT}"
: "${OBS_PARENT_PROJECT}"
: "${CHART_BUNDLE_DIR}"

# Setup .oscrc
sed -i "s|<username>|$OBS_USERNAME|g" /root/.oscrc
sed -i "s|<password>|$OBS_PASSWORD|g" /root/.oscrc

BUNDLE_FILE=$(find ${CHART_BUNDLE_DIR} -name "*.tgz")
CAP_VERSION=$(basename ${BUNDLE_FILE} | perl -lpe 's/.*?-(.*)\.tgz/\1/')
TARGET_OBS_PROJECT="${OBS_PARENT_PROJECT}:${CAP_VERSION}"

# Unpack the release tarball into the current working directory
mkdir bundle_content
pushd bundle_content
tar xvzf "../${BUNDLE_FILE}" > /dev/null

BUNDLED_TARBALLS=$(ls *tgz)
for tarball in ${BUNDLED_TARBALLS}; do
  tar xfv $tarball
done
popd

# Check if $TARGET_OBS_PROJECT already exists on obs
#curl -If "https://build.opensuse.org/project/show/${TARGET_OBS_PROJECT}" && (echo "OBS project ${TARGET_OBS_PROJECT} already exists"; exit 1) || true

# Create OBS project for this release
cat <<HEREDOC | osc meta prj -F - "${TARGET_OBS_PROJECT}"
<project name="${TARGET_OBS_PROJECT}">
  <title>BOSH release sources for CAP ${CAP_VERSION}</title>
  <description/>
  <person userid="alfred-jenkins" role="maintainer"/>
</project>
HEREDOC

# Fetch all sources and upload them to obs
IMAGELISTS=$(find bundle_content/ -name imagelist.txt)
osc co -M "${TARGET_OBS_PROJECT}"

declare -A known_images
declare -A github_repos
declare -A downloaded_github_tarballs
known_images[docker.io/cfcontainerization/pxc]=pxc
known_images[cfcontainerization/coredns]=obs
known_images[registry.suse.com/cap-staging/bits-service]=bits
known_images[cfcontainerization/cf-operator]=github
known_images[registry.suse.com/cap-staging/event-reporter]=github
known_images[registry.suse.com/cap-staging/opi]=github
known_images[registry.suse.com/cap-staging/route-collector]=github
known_images[registry.suse.com/cap-staging/staging-reporter]=github
known_images[registry.suse.com/cap-staging/metrics-collector]=github
known_images[registry.suse.com/cap-staging/route-pod-informer]=github
known_images[registry.suse.com/cap-staging/route-statefulset-informer]=github
known_images[registry.suse.com/cap-staging/recipe-downloader]=github
known_images[registry.suse.com/cap-staging/recipe-executor]=github
known_images[registry.suse.com/cap-staging/recipe-uploader]=github
known_images[cfcontainerization/quarks-job]=github
known_images[splatform/eirinix-loggregator-bridge]=github-commit
known_images[splatform/eirinix-persi]=github-commit
known_images[splatform/eirinix-persi-broker]=github-commit
known_images[splatform/eirinix-persi-broker-setup]=github-commit
known_images[splatform/eirinix-ssh]=github-commit
known_images[splatform/eirinix-ssh-proxy-setup]=github-commit
known_images[registry.suse.com/cap-staging/suse-binary-buildpack]=suse-buildpack
known_images[registry.suse.com/cap-staging/suse-dotnet-core-buildpack]=suse-buildpack
known_images[registry.suse.com/cap-staging/suse-go-buildpack]=suse-buildpack
known_images[registry.suse.com/cap-staging/suse-java-buildpack]=suse-buildpack
known_images[registry.suse.com/cap-staging/suse-nodejs-buildpack]=suse-buildpack
known_images[registry.suse.com/cap-staging/suse-php-buildpack]=suse-buildpack
known_images[registry.suse.com/cap-staging/suse-python-buildpack]=suse-buildpack
known_images[registry.suse.com/cap-staging/suse-ruby-buildpack]=suse-buildpack
known_images[registry.suse.com/cap-staging/suse-staticfile-buildpack]=suse-buildpack
known_images[registry.suse.com/cap-staging/suse-nginx-buildpack]=suse-buildpack

github_repos[cfcontainerization/cf-operator]="https://github.com/cloudfoundry-incubator/quarks-operator"
github_repos[registry.suse.com/cap-staging/event-reporter]="https://github.com/cloudfoundry-incubator/eirini"
github_repos[registry.suse.com/cap-staging/opi]="https://github.com/cloudfoundry-incubator/eirini"
github_repos[registry.suse.com/cap-staging/route-collector]="https://github.com/cloudfoundry-incubator/eirini"
github_repos[registry.suse.com/cap-staging/staging-reporter]="https://github.com/cloudfoundry-incubator/eirini"
github_repos[registry.suse.com/cap-staging/metrics-collector]="https://github.com/cloudfoundry-incubator/eirini"
github_repos[registry.suse.com/cap-staging/route-pod-informer]="https://github.com/cloudfoundry-incubator/eirini"
github_repos[registry.suse.com/cap-staging/route-statefulset-informer]="https://github.com/cloudfoundry-incubator/eirini"
github_repos[registry.suse.com/cap-staging/recipe-downloader]="https://github.com/cloudfoundry-incubator/eirini-staging/"
github_repos[registry.suse.com/cap-staging/recipe-executor]="https://github.com/cloudfoundry-incubator/eirini-staging/"
github_repos[registry.suse.com/cap-staging/recipe-uploader]="https://github.com/cloudfoundry-incubator/eirini-staging/"
github_repos[registry.suse.com/cap-staging/suse-binary-buildpack]="https://github.com/SUSE/cf-binary-buildpack"
github_repos[registry.suse.com/cap-staging/suse-dotnet-core-buildpack]="https://github.com/SUSE/cf-dotnet-core-buildpack"
github_repos[registry.suse.com/cap-staging/suse-go-buildpack]="https://github.com/SUSE/cf-go-buildpack"
github_repos[registry.suse.com/cap-staging/suse-java-buildpack]="https://github.com/SUSE/cf-java-buildpack"
github_repos[registry.suse.com/cap-staging/suse-nginx-buildpack]="https://github.com/SUSE/cf-nginx-buildpack"
github_repos[registry.suse.com/cap-staging/suse-nodejs-buildpack]="https://github.com/SUSE/cf-nodejs-buildpack"
github_repos[registry.suse.com/cap-staging/suse-php-buildpack]="https://github.com/SUSE/cf-php-buildpack"
github_repos[registry.suse.com/cap-staging/suse-python-buildpack]="https://github.com/SUSE/cf-python-buildpack"
github_repos[registry.suse.com/cap-staging/suse-ruby-buildpack]="https://github.com/SUSE/cf-ruby-buildpack"
github_repos[registry.suse.com/cap-staging/suse-staticfile-buildpack]="https://github.com/SUSE/cf-staticfile-buildpack"
github_repos[splatform/eirinix-loggregator-bridge]="https://github.com/SUSE/eirini-loggregator-bridge"
github_repos[splatform/eirinix-persi]="https://github.com/SUSE/eirini-persi"
github_repos[splatform/eirinix-persi-broker]="https://github.com/SUSE/eirini-persi-broker/"
github_repos[splatform/eirinix-persi-broker-setup]="https://github.com/SUSE/eirinix-helm-release/"
github_repos[splatform/eirinix-ssh]="https://github.com/SUSE/eirini-ssh/"
github_repos[splatform/eirinix-ssh-proxy-setup]="https://github.com/SUSE/eirinix-helm-release/"
github_repos[cfcontainerization/quarks-job]="https://github.com/cloudfoundry-incubator/quarks-job"

handle_release_image() {
  local package_name=$(echo $image | sed -E 's/.*\/([^/]+):.*/\1/')
  local package_version=$(echo $image | sed -E 's/.*-(.*?)/\1/')
  local url="${S3_BASE_URL}${package_name}-${package_version}.tgz"

  osc mkpac "${package_name}"
  pushd "${package_name}"
  wget "${url}"
  osc add *
  osc ci -f -m "commit"
  popd
}

handle_github_based_image() {
  local image=$1
  local version_regex=$2
  local package_version=$(echo $image | sed -E ${version_regex})
  local package_name=$(echo $image | sed -E 's/.*\/([^/]+):.*/\1/')
  local docker_repo=$(echo $image | sed -E 's/(.+):.*/\1/')
  local github_repo=${github_repos[$docker_repo]}

  if [ -z "${github_repo}" ]; then
    echo "Github repository for image '${image}' not set. Abort."
    exit 1
  fi

  local url="${github_repo}/archive/${package_version}.zip"
  if [ -n "${downloaded_github_tarballs[$url]+unset}" ]; then
    osc mkpac "${package_name}"
    pushd "${package_name}"

    echo "Github sources for ${image_name} (${url}) were already downloaded in package ${downloaded_github_tarballs[$url]}." | tee README
    osc add *
    osc ci -f -m "commit"

    popd
    return
  fi
  downloaded_github_tarballs[${url}]="${package_name}"

  osc mkpac "${package_name}"
  pushd "${package_name}"

  wget ${url}
  osc add *
  osc ci -f -m "commit"
  popd
}

handle_bits_image() {
  local image=$1
  local package_version=$(echo $image | sed -E 's/.*:bits-([^-]*?).*/\1/')
  local package_name=$(echo $image | sed -E 's/.*\/([^/]+):.*/\1/')

  osc mkpac "${package_name}"
  pushd "${package_name}"

  wget "https://github.com/SUSE/bits-service-release/archive/bits-${package_version}.zip"
  osc add *
  osc ci -f -m "commit"
  popd
}

handle_pxc_image() {
  local image=$1
  local version=$(echo $image | sed -E 's/.*:(.*)/\1/')

  osc mkpac pxc-docker
  pushd pxc-docker

  # Fetch build sources
  wget "https://github.com/SUSE/pxc-docker/archive/${version}.zip"

  # Fetch percona sources
  unzip "${version}.zip" "pxc-docker-${version}/Dockerfile"
  urls=$(grep -o -E 'http[s]?://[^ ]*' "pxc-docker-${version}/Dockerfile"| grep -v "\.repo")
  for url in ${urls}; do
    wget ${url}
    osc add $(basename ${url})
  done
  osc add "${version}.zip"
  osc ci -f -m "commit"
  popd
}


for imagelist in ${IMAGELISTS}; do
  for image in $(cat $imagelist); do
    pushd "${TARGET_OBS_PROJECT}"

    image_name=$(echo $image | sed -E 's/(.*):.*/\1/')
    if [ -z "${known_images[$image_name]+unset}" ]; then
      type="default"
    else
      type=${known_images[$image_name]}
    fi

    case "${type}" in
    github-commit)
      handle_github_based_image "${image}" 's/.*(\w{7})$/\1/g'
      ;;
    github)
      handle_github_based_image "${image}" 's/.*:([^-]*?).*/\1/'
      ;;
    suse-buildpack)
      handle_github_based_image "${image}" 's/.*-([^-]*?)/v\1/'
      ;;
    obs)
      # TODO: Implement
      ;;
    bits)
      handle_bits_image $image
      ;;
    pxc)
      handle_pxc_image $image
      ;;
    default | *)
      handle_release_image $image
      ;;
    esac

    popd
  done
done

# Add the stemcell source project
osc linkpac -c "${OBS_STEMCELL_PROJECT}" "${TARGET_OBS_PROJECT}"
