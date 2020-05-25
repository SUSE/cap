#!/bin/bash

set -eux

# Make sure that all required variabels are set
: "${OBS_USERNAME}"
: "${OBS_PASSWORD}"
: "${OBS_PARENT_PROJECT}"
: "${CHART_BUNDLE_DIR}"

# Setup .oscrc
sed -i "s|<username>|$OBS_USERNAME|g" /root/.oscrc
sed -i "s|<password>|$OBS_PASSWORD|g" /root/.oscrc

BUNDLE_FILE=$(find ${CHART_BUNDLE_DIR} -name "*.tgz")
CAP_VERSION=$(basename ${BUNDLE_FILE} | perl -lpe 's/.*?-(.*)\.tgz/\1/')
CAP_PROJECT="${OBS_PARENT_PROJECT}:${CAP_VERSION}"

TARGET_OBS_PROJECT="${CAP_PROJECT}:reviewed"
# Create OBS project for this release
cat <<HEREDOC | osc meta prj -F - "$TARGET_OBS_PROJECT"
<project name="${TARGET_OBS_PROJECT}">
  <title>BOSH release sources for CAP ${CAP_VERSION}</title>
  <description/>
  <person userid="alfred-jenkins" role="maintainer"/>
  <group groupid="cloud-platform-maintainers" role="maintainer"/>
  <group groupid="legal-auto" role="reviewer"/>
</project>
HEREDOC

#TODO: maybe take care of the following here: Cloud:Platform:sources:scf Cloud:Platform:sources:buildpacks Cloud:Platform:buildpacks:dependencies Cloud:Platform:sources:sidecars
PROJECTS="${CAP_PROJECT}"
for SOURCE_OBS_PROJECT in ${PROJECTS}; do
  for PACKAGE in $(osc ls ${SOURCE_OBS_PROJECT}); do
    osc submitrequest --yes --message=legal-review "${SOURCE_OBS_PROJECT}" "${PACKAGE}" "${SOURCE_OBS_PROJECT}:reviewed"
  done
done
