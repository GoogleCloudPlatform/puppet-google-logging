# Cloud Operations Puppet Agents Testing

## Overview

This repo leverages the following for integration testing:

- [Google Compute Engine](https://cloud.google.com/compute): Test instances
- [Github Actions](https://github.com/features/actions): Continuous integration
- [Packer](https://www.packer.io/): Build test instance base images
- [Terraform](https://www.terraform.io/): Deploy test instances
- [Inspec](https://github.com/inspec/inspec): Perform validation

## Google Compute Engine

Google Compute Engine hosts the testing environment, ensure the following APIs are enabled in the project:

```bash
gcloud services enable compute.googleapis.com
gcloud services enable storage-api.googleapis.com
```

Create a service account with the following roles:

- Compute Admin
- Service Account User

Create a service account json key, which will be referenced during Github Actions configuration.

## Github Actions

Github actions requires several secrets. Navigate to the repositories secrets and add the following:

- **GCP_PROJECT_ID**: Google Cloud project_id
- **GCP_SA_KEY**: Google Cloud service account json key
- **SSH_PRIVATE_KEY**: keypair private key
- **SSH_PUBLIC_KEY**: keypair public key

#### Keypair

You can generate an SSH keypair with `ssh-keygen`. This keypair will be used for Puppet and Inspec's ssh connectivity.

## Packer

Packer will require access to Google APIs. This [guide provides](https://cloud.google.com/build/docs/building/build-vm-images-with-packer) examples on how to setup your working environment.

Packer is used to build Linux images once. These images will be deployed by CI to speed up the test process and avoid inconsistency issues with apt / yum repositories. Windows images are built manually, but stored in the same manner.

The project being used for CI deployments should have read access to these images.

### Linux

Packer is used to "bake" `puppet` and `gcloud sdk` into base images. Using base images allows tests to be repeatable, reliable, fast.

Base images must be built prior to running tests. Install `packer` and then run the following commands in the `test/packer` directory:
```bash
./build.sh ubuntu-2004-lts
./build.sh ubuntu-1804-lts
./build.sh ubuntu-1604-lts
./build.sh debian-10
./build.sh debian-9
./build.sh centos-s8
./build.sh centos-8
./build.sh centos-7
./build.sh rhel-8
./build.sh rhel-7
./build.sh sles-12
./build.sh sles-15
```

### Windows

Packer is currently not used to build Windows images. Windows images can be built manually with the following steps:
1. Deploy windows 2019 datacenter
2. Install Puppet Agent
   1. Download: `Invoke-WebRequest -Uri http://downloads.puppetlabs.com/windows/puppet7/puppet-agent-7.3.0-x64.msi -OutFile C:/agent.msi`
   2. Run installer: `C:\agent.msi`
   3. Choose default settings, even for "puppet server". CI will run in serverless mode with `puppet apply`
3. Install Ruby
   1. Download: `Invoke-WebRequest -Uri https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-3.0.1-1/rubyinstaller-3.0.1-1-x64.exe -OutFile C:/ruby.exe`
   2. Install: `C:\ruby.exe`
   3. Skip ridk install at the end
4. Install r10k
   1. In a new Powershell windows, run: `gem install r10k`
5. Shutdown
6. Add user
   1. Create a local user (not with a microsoft email)
   2. username: `ci`
   3. password: Can be anything. CI will use an ssh key for authentication
   4. Set the account type to administrator
7. Install Powershell Core
   1.  `Invoke-WebRequest -Uri https://github.com/PowerShell/PowerShell/releases/download/v7.1.3/PowerShell-7.1.3-win-x64.msi -OutFile C:/pw.msi`
   2.  `C:\pw.msi`
       1.  Enable "powershell remoting" during the install
8.  Install SSH For Powershell
   3.  `Invoke-WebRequest -Uri https://github.com/PowerShell/Win32-OpenSSH/releases/download/V8.6.0.0p1-Beta/OpenSSH-Win64.zip -OutFile C:/ssh.zip`
   4.  Extract the zip
   5.  Run: `C:\ssh\OpenSSH-Win64\install-sshd.ps1`
   6. Allow ssh through the firewall
      1. Run: `New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22`
   7. Manage the service
      1. `net start sshd`
      2. `Set-Service sshd -StartupType Automatic`
      3. `Set-Service ssh-agent -StartupType Automatic`
      4. `Restart-Service sshd`
   8. administrators_authorized_keys
      1. Run notepad as administrator
      2. Paste your public key (the one used for Github actions). It will look something like this, but much longer. Make sure the username `ci` is appended at the end.
      ```
      ssh-rsa AAAAB3NzaC1yc2EAAAAPz5teSUtfo1A6UDbls8EFQRlxEICIgRlUFe8JPVL3QOvpqY7Fit0zRPJXWs7L4b1PHA5+rEUNAl9LUdBzHb/kJjnXepe8qoNRGZZiazd738= ci
      ```
   9. Test SSH, where `-i` points to your public key used for github actions
      1.  `ssh -i id_rsa ci@34.66.152.33`
          1.  You should not be prompted for a password
          2.  Run `puppet help` to verify
9. Create Disk Image
   1. Navigate to Compute Engine --> Storage --> Disks
   2. Select the disk for your instance
   3. Choose "Create Image"
      1. Name it `windows-2019-0`
      2. Set family to `puppet-windows-2019`
      3. Future images can be incremented, `puppet-windows-2019-1` and so on.
   4. Ensure `terraform/main.tf` image mapping is pointing to the correct windows image

## Terraform

Terraform is used by the Github Actions workflow, no setup configuraton is required. The configuration can be found in `test/terraform`.

## Inspec

Inspec is used for running integration tests. Test cases are found in `test/cases`. No setup configuraton is required. 

The directory structure is as follows:

```bash
test/cases/{platform}/{agent_type}/{version}/{action}/
```

For example, ops-agent version 1.04 on linux:
```bash
test/cases/linux/ops-agent/1.0.4/install/
```

Tests with specific versions will:
1. Install the agent
2. Upgrade the agent
3. Uninstall the agent
4. Install the agent with a custom configuration

Inspec output will look like this:
```bash

Profile: tests from test/cases/linux/ops-agent/1.0.4/custom_config/spec/spec.rb (tests from test.cases.linux.ops-agent.1.0.4.custom_config.spec.spec.rb)
Target:  ssh://ci@34.75.191.137:22

  Service google-cloud-ops-agent.target
     ✔  is expected to be installed
     ✔  is expected to be enabled
     ✔  is expected to be running
  System Package google-cloud-ops-agent
     ✔  is expected to be installed
     ✔  version is expected to match /1.0.4/
  File /etc/google-cloud-ops-agent/config.yaml
     ✔  is expected to exist
     ✔  owner is expected to eq "root"
     ✔  group is expected to eq "root"
     ✔  mode is expected to cmp == "0644"
     ✔  sha256sum is expected to eq "202256588869d4efc115317829c0435cdd8caf2e876f259509d552e974b4f907"

Test Summary: 10 successful, 0 failures, 0 skipped
```
