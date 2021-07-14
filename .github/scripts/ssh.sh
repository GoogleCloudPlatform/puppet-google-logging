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

# This script waits for an instance to boot and allow ssh connections,
# an alternative approach to sleeping N minutes after deploying instances.
#
#      - name: Configure SSH
#        run: |
#          INSTANCE=$(echo ${{ matrix.distro }}-${{ matrix.agent_type }}-${{ matrix.version }}-$(git rev-parse --short HEAD) | tr -d '.')
#          ./.github/scripts/ssh.sh $INSTANCE
#        env:
#          PROJECT: ${{ secrets.GCP_PROJECT_ID }}
#        timeout-minutes: 10

set -e

if [ -z "$1" ]; then
    echo "\$1 not set, should be instance name"
    exit 1
fi
INSTANCE=$1

# The project_id the instance was deployed to
if [ -z "$PROJECT" ]; then
    echo "PROJECT not set"
    exit 1
fi

# The zone the instance was deployed to
if [ -z "$ZONE" ]; then
    echo "ZONE not set"
    exit 1
fi

ADDRESS=$(gcloud --project "${PROJECT}" compute instances describe --zone "${ZONE}" "${INSTANCE}" --format=json | jq -r '.networkInterfaces[0].accessConfigs[0].natIP')

ssh_key() {
    rm -f ~/.ssh/known_hosts

    echo "adding target ${ADDRESS} to known hosts"
    # foreever, timeout is handled by Github Actions pipeline
    while :
    do
        ssh-keyscan "${ADDRESS}" >> ~/.ssh/known_hosts && break
        sleep 5
    done

    # sleep again to allow ssh metadata key to populate
    sleep 20

    echo "finished adding ${ADDRESS} to known hosts"
}

ssh_key