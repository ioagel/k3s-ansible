#!/bin/bash

# download-boxes.sh
# Check all molecule.yml files for required Vagrant boxes and download the ones that are not
# already present on the system.

set -euo pipefail

GIT_ROOT=$(git rev-parse --show-toplevel)
PROVIDER=virtualbox

# Read all boxes for all platforms from the "molecule.yml" files
all_raw_boxes=$(cat "${GIT_ROOT}"/molecule/*/molecule.yml |
    yq -r '.platforms[].box') # Read the "box" property of each node under "platforms"

# Replaces vagrant box environment var if set or the default
if [ -z ${VAGRANT_OS+x} ]; then
    # shellcheck disable=SC2016
    all_boxes=$(echo "$all_raw_boxes" | sed 's/${VAGRANT_OS:-//;s/}$//')
else
    all_boxes="${all_raw_boxes/$\{VAGRANT_OS:-*/$VAGRANT_OS}"
fi

all_boxes=$(echo "$all_boxes" |
    grep --invert-match --regexp=--- | # Filter out file separators
    sort |
    uniq)

# Read the boxes that are currently present on the system (for the current provider)
present_boxes=$(
    (vagrant box list |
        grep "${PROVIDER}" | # Filter by boxes available for the current provider
        awk '{print $1;}' |  # The box name is the first word in each line
        sort |
        uniq) ||
        echo "" # In case any of these commands fails, just use an empty list
)

# The boxes that we need to download are the ones present in $all_boxes, but not $present_boxes.
download_boxes=$(comm -2 -3 <(echo "${all_boxes}") <(echo "${present_boxes}"))

# Actually download the necessary boxes
if [ -n "${download_boxes}" ]; then
    echo "${download_boxes}" | while IFS= read -r box; do
        vagrant box add --provider "${PROVIDER}" "${box}"
    done
fi
