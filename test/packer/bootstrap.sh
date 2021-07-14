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

set -e

apt_install() {
    sudo apt-get update
    sudo apt-get install -qq -y wget curl rsync

    if lsb_release -a | grep focal >/dev/null; then
        code_name="focal"
    elif lsb_release -a | grep bionic >/dev/null; then
        code_name="bionic"
    elif lsb_release -a | grep xenial >/dev/null; then
        code_name="xenial"
    elif lsb_release -a | grep buster >/dev/null; then
        code_name="buster"
    elif lsb_release -a | grep stretch >/dev/null; then
        code_name="stretch"
    else
        echo "Debian|Ubuntu version not supported"
        lsb_release -a
        exit 1
    fi

    wget "https://apt.puppet.com/puppet7-release-${code_name}.deb"
    sudo dpkg -i "puppet7-release-${code_name}.deb"

    sudo apt-get update
    sudo apt-get install -qq -y r10k puppet-agent dbus

    # remove auto updates, which could lock apt during CI runs, causing failures
    sudo apt-get remove -y unattended-upgrades
}

yum_install() {
    sudo yum install -y wget curl rsync redhat-lsb

    majorversion=$(lsb_release -rs | cut -f1 -d.)
    case $majorversion in
    7 | 8)
        ;;
    *)
        echo "RHEL or CentOS versin not supported: ${majorversion}"
        exit 1
    esac

    sudo rpm -Uvh "https://yum.puppet.com/puppet7-release-el-${majorversion}.noarch.rpm"
    sudo yum install -y puppet-agent
    sudo /opt/puppetlabs/puppet/bin/gem install r10k

    sudo ln -s /opt/puppetlabs/bin/puppet /usr/bin/puppet
    sudo ln -s /opt/puppetlabs/puppet/bin/r10k /usr/bin/r10k

    sudo yum clean packages
}

zypper_install() {
    sudo zypper install -y wget curl rsync

    if grep VERSION_ID /etc/os-release | grep 15; then
        majorversion="15"
    elif grep VERSION_ID /etc/os-release  | grep 12; then
        majorversion="12"
    else
        echo "Sles version not supported"
        cat /etc/os-release
        exit 1
    fi

    sudo rpm -Uvh "https://yum.puppet.com/puppet7-release-sles-${majorversion}.noarch.rpm"
    sudo zypper --no-gpg-checks --gpg-auto-import-keys install -y puppet-agent
    sudo /opt/puppetlabs/puppet/bin/gem install r10k

    sudo ln -s /opt/puppetlabs/bin/puppet /usr/bin/puppet
    sudo ln -s /opt/puppetlabs/puppet/bin/r10k /usr/bin/r10k
}

install_puppet() {
    if command -v apt-get >/dev/null; then
        apt_install
    elif command -v yum >/dev/null; then
        yum_install
    elif command -v zypper >/dev/null; then
        zypper_install
    else
        echo "No supported package manager found"
        exit 1
    fi
}

# sometimes gcloud sdk is not installed on the base
# image but packer assumes it exists
install_gcloud() {
    if ! command -v COMMAND &> /dev/null
    then
        curl https://sdk.cloud.google.com > install.sh
        bash install.sh --disable-prompts
    fi
}

install_puppet
install_gcloud