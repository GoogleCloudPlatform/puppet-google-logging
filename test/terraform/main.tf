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

variable "project" {
  default = "united-aura-313415"
}

variable "preemptible" {
  default = true
}

// ci will create this key, but it can be changed to something
// else if desired. Installing an ssh key allows tools like
// inspec to interact with the vm without dealing with
// gcloud ssh. Changing this key is not useful unless running
// from a workstation with a different key
variable "ssh_public_key" {
  description = "ssh key to be used for linux systems"
  default = "~/.ssh/id_rsa.pub"
}

variable "os" {}

variable "image" {
  description = "Images built from test/packer"
  type = map
  default = {
    "ubuntu-2004"  = "puppet-ubuntu-2004-lts"
    "ubuntu-1804"  = "puppet-ubuntu-1804-lts"
    "ubuntu-1604"  = "puppet-ubuntu-1604-lts"
    "debian-10"    = "puppet-debian-10"
    "debian-9"     = "puppet-debian-9"
    "centos-s8"    = "puppet-centos-stream-8"
    "centos-8"     = "puppet-centos-8"
    "centos-7"     = "puppet-centos-7"
    "rhel-8"       = "puppet-rhel-8"
    "rhel-7"       = "puppet-rhel-7"
    "suse-15"      = "puppet-sles-15"
    "suse-12"      = "puppet-sles-12"
    "windows-2019" = "windows-2019-2"
  }
}

module "instance" {
  source         = "./instance/"
  project        = var.project
  source_image   = var.image[var.os]
  preemptible    = var.preemptible
  ssh_public_key = "~/.ssh/id_rsa.pub"
}