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

describe service('stackdriver-agent') do
    it { should be_installed }
    it { should be_enabled }
    it { should be_running }
end

describe file('/etc/stackdriver/collectd.conf') do
    it { should exist }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0644' }
    its('sha256sum') { should eq '0646751e0c953ff790a812841c2d3f47e8304f59476734e135e4607f4a964984' }
end

describe file('/etc/stackdriver/collectd.d/example_plugin.conf') do
    it { should exist }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0644' }
    its('sha256sum') { should eq '8b68d474a8115aab18e61eb877a7c8a16715cd8346c98c9d645ef0813fbcb02f' }
end

