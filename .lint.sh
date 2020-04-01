#!/usr/bin/env bash

retcode=0
ROOT_DIR=$(git rev-parse --show-toplevel)

echo "Linting shell scripts"
SH_FILES=$(find "$ROOT_DIR" -type f -name '*.sh' -o -name '*.ksh' -o -name '*.bash' | grep -v "shunit2")
shellcheck --severity=warning $SH_FILES || retcode=1

echo "Linting yamls"
YML_FILES=$(find "$ROOT_DIR" -type f -name '*.yaml' -o -name '*.yml' | grep -v "shunit2")
yamllint -d "{extends: relaxed, rules: {line-length: {max: 120}}}" --strict $YML_FILES || retcode=1

if [[ $retcode == 1 ]] ; then
    echo "Linting failed" && exit 1
else
    echo "Linting passed"
fi
