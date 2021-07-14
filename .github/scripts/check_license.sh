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
#
# This script returns a non 0 exit code when a source file is found
# without a license header.

set -e

if ! command -v addlicense &> /dev/null
then
    echo "addlicense command could not be found: https://github.com/google/addlicense"
    exit 1
fi

# Source types to check
ALL_EXT=("pp" "tf" "rb" "conf" "yaml" "ps1" "sh")

# Array will contain all source files to check
ALL_SRC=()

# Find source files and add them to ALL_SRC
for src_type in "${ALL_EXT[@]}"; do
    src_files=$(find . -name "*.${src_type}" -type f | sort)
    ALL_SRC+=("$src_files")
done

# Check licenses, will return 1 if a license is missing
echo "The following source files are missing a license header:"
# Quoting ALL_SRC does not play nice with addlicense cli, array expansion is not a concern here
# shellcheck disable=SC2068
addlicense \
    -check \
    -l apache \
    -c "Google LLC" \
    ${ALL_SRC[@]}