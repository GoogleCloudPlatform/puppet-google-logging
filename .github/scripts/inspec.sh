#!/usr/bin/env bash

# Copyright 2021 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This script runs inspec tests using https://cinc.sh/, a free distribution of Chef's Inspec.
# Workflows can call this script like this:
#
#      - name: Test Install
#        run: |
#          INSTANCE=$(echo ${{ matrix.distro }}-${{ matrix.agent_type }}-${{ matrix.version }}-$(git rev-parse --short HEAD) | tr -d '.')
#          export ADDRESS=$(gcloud --project "${PROJECT}" compute instances describe --zone "${ZONE}" "${INSTANCE}" --format=json | jq -r '.networkInterfaces[0].accessConfigs[0].natIP')
#          ./.github/scripts/puppet.sh
#          ./.github/scripts/inspec.sh
#        env:
#          PLATFORM: linux
#          VERSION: ${{ matrix.version }}
#          AGENT_TYPE: ${{ matrix.agent_type }}
#          ACTION: install
#        timeout-minutes: 10

# Platform is used to determine the diectory path in test/cases/
if [ -z "$PLATFORM" ]; then
    echo "PLATFORM not set"
    exit 1
fi

# Version is used to determine the diectory path in test/cases/
if [ -z "$VERSION" ]; then
    echo "VERSION not set"
    exit 1
fi

# Agent type is used to determine the diectory path in test/cases/
if [ -z "$AGENT_TYPE" ]; then
    echo "AGENT_TYPE not set"
    exit 1
fi

# Action is used to determine the diectory path in test/cases/
if [ -z "$ACTION" ]; then
    echo "ACTION not set"
    exit 1
fi

# Address is the ip address targetted by the test suite
if [ -z "$ADDRESS" ]; then
    echo "ADDRESS not set"
    exit 1
fi

run_inspec() {
    # Inspec is Apache 2.0 licensed, but requires that the license
    # is accepted https://github.com/inspec/inspec/blob/master/LICENSE
    export CHEF_LICENSE="accept-no-persist"

    inspec exec \
        "test/cases/${PLATFORM}/${AGENT_TYPE}/${VERSION}/${ACTION}/spec/spec.rb" \
        -t "ssh://ci@${ADDRESS}" \
        -i ~/.ssh/id_rsa || return

    # exit on success
    exit 0
}

# Run up to 3 times, sometimes Github Actions --> GCP connections can be dropped
# causing failures unrelated to the test.
count=3
for i in $(seq ${count}); do
    echo "Inspec attempt ${i} of ${count}"
    run_inspec

    echo "Attempt failed, sleep 10 seconds before trying again"
    sleep 10
done

# Exit non zero on failure
exit 1