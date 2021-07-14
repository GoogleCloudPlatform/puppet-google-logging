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

describe service('google-cloud-ops-agent') do
    it { should be_installed }
    it { should be_enabled }
    it { should be_running }
end

describe package('google-cloud-ops-agent') do
    it { should be_installed }
    # This code will break, if 2.x.x is ever released
    its('version') { should match /2./ }
end

describe file('/etc/google-cloud-ops-agent/config.yaml') do
    it { should exist }
end