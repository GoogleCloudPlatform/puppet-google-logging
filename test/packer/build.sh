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

image_family=$1

cat <<END>packer.json
      {
      "builders": [
        {
          "image_name": "$(echo ${image_family}-$(git rev-parse --short HEAD))",
          "image_family": "puppet-${image_family}",
          "source_image_family": "${image_family}",
          "type": "googlecompute",
          "project_id": "united-aura-313415",
          "ssh_username": "packer",
          "zone": "us-east1-b",
          "startup_script_file": "bootstrap.sh",
          "scopes": [
            "https://www.googleapis.com/auth/userinfo.email",
            "https://www.googleapis.com/auth/compute",
            "https://www.googleapis.com/auth/devstorage.full_control"
          ]
        }
        ]
      }
END

packer build packer.json

rm -f packer.json