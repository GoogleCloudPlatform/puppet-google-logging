# @summary Installs a Google Cloud agent
#
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
# Installs a Google Cloud agent
#
# @example
#   google_cloud_ops::agent { 'ops-agent':
#    agent_type    => 'ops-agent',
#    package_state => 'present',
#    version       => '2.0.1',
#    main_config   => 'puppet:///modules/example/ops_agent/config.yaml',
#  }
define google_cloud_ops::agent (
  String $agent_type,
  String $version = 'latest',
  String $package_state = 'present',
  String $main_config = '',
  String $additional_config_dir = ''
) {

  # windows globals
  if $facts['os']['family'] == 'windows' {
    $system_root = $facts['system32']
    $googet = 'C:\\ProgramData\\GooGet\\googet.exe'
    if $agent_type == 'ops-agent' {
      $service_name = 'google-cloud-ops-agent'
      $config_path = "C:\\Program Files\\Google\\Cloud Operations\\Ops Agent\\config\\config.yaml"
    }

  # linux globals
  } else {
    $tmp_dir = "/tmp/${agent_type}"
    $script_path = "${tmp_dir}/add-monitoring-agent-repo.sh"
    if $agent_type == 'ops-agent' {
      $service_name = 'google-cloud-ops-agent'
      $config_path    = '/etc/google-cloud-ops-agent/config.yaml'
      $script_source  = 'https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh'
    } elsif $agent_type == 'monitoring' {
      $service_name   = 'stackdriver-agent'
      $config_path    = '/etc/stackdriver/collectd.conf'
      $plugins_path   = '/etc/stackdriver/collectd.d'
      $script_source  = 'https://dl.google.com/cloudagents/add-monitoring-agent-repo.sh'
    } elsif $agent_type == 'logging' {
      $service_name   = 'google-fluentd'
      $config_path    = '/etc/google-fluentd/google-fluentd.conf'
      $plugins_path   = '/etc/google-fluentd/plugin'
      $script_source  = 'https://dl.google.com/cloudagents/add-logging-agent-repo.sh'
    }
  }

  if $facts['os']['family'] == 'windows' {
    if $package_state == 'present' {
      exec { "install-repo-${agent_type}":
        command => "${googet} addrepo google-cloud-ops-agent-windows https://packages.cloud.google.com/yuck/repos/google-cloud-ops-agent-windows-all",
        unless  => "${system_root}\\cmd.exe /c ${googet} listrepos | findstr /i \"google-cloud-ops-agent-windows\""
      }

      if $agent_type == 'ops-agent' {
        exec { "install-${agent_type}":
          command => "${googet} -noconfirm install google-cloud-ops-agent.x86_64.${version}",
          unless  => "${system_root}\\cmd.exe /c ${googet} verify google-cloud-ops-agent | findstr /i \"Verification of google-cloud-ops-agent.x86_64.${version} completed\"",
        }
      }

      if $main_config.length > 0  {
        file { $config_path:
          ensure  => file,
          source  => $main_config,
          owner   => 'Administrators',
          mode    => '0664',
          require => Exec["install-${agent_type}"],
          notify  => Exec['wait-for-start']
        }

        # We need to wait for the agent service to start to prevent restarting
        # it too soon, which results in an error
        # ping with a timeout is the best way to get windows to sleep over ssh
        exec { 'wait-for-start':
          command => "${system_root}\\ping.exe -n 20 127.0.0.1"
        }

        # Puppet does not support restarting services that have dependant services
        # https://puppet.com/docs/puppet/5.5/types/service.html#service-provider-windows
        exec { "restart-${agent_type}":
          command     => "${system_root}\\cmd.exe /c net stop ${service_name} /y",
          subscribe   => File[$config_path],
          refreshonly => true,
          notify      => Service[$service_name],
        }
      }

    } else {
      if $agent_type == 'ops-agent' {
        exec { "remove-${agent_type}":
          command => "${googet} -noconfirm remove google-cloud-ops-agent",
          onlyif  => "${system_root}\\cmd.exe /c ${googet} verify google-cloud-ops-agent | findstr /i \"Verification of google-cloud-ops-agent.x86_64.${version} completed\"",
        }
      }
    }

  # All other supported platforms are Linux
  } else {
      file { $tmp_dir:
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755'
    }

    # puppet module install lwf-remote_file --version 1.1.3
    remote_file { $script_path:
      ensure => present,
      source => $script_source,
      mode   => '0700',
    }

    if $package_state == 'present' {
        exec { "install-${agent_type}":
          command  => "${script_path} --also-install --version=${version}",
          provider => shell,
          onlyif   => "${script_path} --also-install --version=${version} --dry-run | grep 'installation succeeded'"
        }
    } else {
        exec { "install-${agent_type}":
          command  => "${script_path} --uninstall --remove-repo",
          provider => shell,
          onlyif   => "${script_path} --uninstall --remove-repo --dry-run | grep 'uninstallation succeeded'"
        }
    }

    if $package_state == 'present' {
      if $main_config.length > 0  {
        file { $config_path:
          ensure  => file,
          source  => $main_config,
          owner   => 'root',
          group   => 'root',
          mode    => '0644',
          notify  => Service[$service_name],
          require => Exec["install-${agent_type}"]
        }
      }
      if $additional_config_dir.length > 0 {
        file { $plugins_path:
          ensure  => directory,
          source  => $additional_config_dir,
          recurse => true,
          owner   => 'root',
          group   => 'root',
          mode    => '0644',
          notify  => Service[$service_name],
          require => Exec["install-${agent_type}"]
        }
      }
    }
  }

  if $package_state == 'present' {
    service { $service_name:
      ensure     => 'running',
      enable     => 'true',
      hasrestart => 'true',
      require    => Exec["install-${agent_type}"]
    }
  } else {
    service { $service_name:
      ensure => 'stopped',
      enable => 'false'
    }
  }
}
