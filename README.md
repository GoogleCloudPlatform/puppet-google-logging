# Google Cloud Operations Agents Puppet Integration

[![Status](https://github.com/BlueMedora/google-puppet-agents/workflows/linux/badge.svg)](https://github.com/BlueMedora/google-puppet-agents/linux)
[![Status](https://github.com/BlueMedora/google-puppet-agents/workflows/windows/badge.svg)](https://github.com/BlueMedora/google-puppet-agents/windows)
[![Status](https://github.com/BlueMedora/google-puppet-agents/workflows/shellcheck/badge.svg)](https://github.com/BlueMedora/google-puppet-agents/shellcheck)

## Description

Puppet module for [Google Cloud Operations agents](https://cloud.google.com/stackdriver/docs/solutions/agents).

## Support Matrix

- Linux
  - [Ops Agent](https://cloud.google.com/stackdriver/docs/solutions/agents/ops-agent)
    - [Supported operating systems](https://cloud.google.com/stackdriver/docs/solutions/agents/ops-agent#supported_operating_systems)
  - [Monitoring Agent](https://cloud.google.com/stackdriver/docs/solutions/agents/monitoring)
    - [Supported Operating Systems](https://cloud.google.com/stackdriver/docs/solutions/agents/monitoring#supported_operating_systems)
  - [Logging Agent](https://cloud.google.com/stackdriver/docs/solutions/agents/logging)
    - [Supported Operating Systems](https://cloud.google.com/stackdriver/docs/solutions/agents/logging#supported_operating_systems)
- Windows
  - [Cloud Ops Agent](https://cloud.google.com/stackdriver/docs/solutions/agents/ops-agent)
    - [Supported Operating Systems](https://cloud.google.com/stackdriver/docs/solutions/agents/ops-agent#supported_operating_systems)

## Requirements

https://cloud.google.com/stackdriver/docs/solutions/agents/ops-agent#access

## Prerequisite Modules

The following modules must be available on the Puppet server:
- [lwf-remote_file](https://forge.puppet.com/modules/lwf/remote_file)

## Install Module

### Install Module from Source
To build the module from source:
- Build: `pdk build`
- Copy to your Puppet server
  - The built module can be found in `pkg/`
- Install: `puppet module install ops-cloud_ops-0.1.0.tar.gz`
- Verify: `puppet module list`

## Usage

| Parameter               | Default       | Description                                                       |
| ---                     | ---           | ---                                                               |
| `agent_type`            | Required      | The agent type: `ops-agent`, `monitoring`, `logging`              |
| `package_state`         | `present`     | Whether the agent should be installed or not (`present` | `absent`) |
| `version`               | `latest`      | The version variable can be used to specify which version of the agent to install. The allowed values are latest, MAJOR_VERSION.*.* and MAJOR_VERSION.MINOR_VERSION.PATCH_VERSION, which are described in detail below. |
| `main_config`           |               | Optional value for overriding the default configuration. For configuration syntax instructions, see [Ops Agent Config](https://cloud.google.com/stackdriver/docs/solutions/agents/ops-agent/configuration), [Logging Agent Config](https://cloud.google.com/logging/docs/agent/logging/configuration), and [Monitoring Agent](https://cloud.google.com/monitoring/agent/monitoring/configuration for configuration) for more details.           |
| `additional_config_dir` |               | Optional value for overriding the plugins directory for the `monitoring` or `logging` agents |

### Version

- version=`latest`
  - This setting makes it easier to keep the agent version up to date, however it does come with a potential risk. When a new major version is released, the policy may install the latest version of the agent from the new major release, which may introduce breaking changes. For production environments, consider using the version=MAJOR_VERSION.*.* setting below for safer agent deployments.

- version=`MAJOR_VERSION.*.*`
  - When a new major release is out, this setting ensures that only the latest version from the specified major version is installed, which avoids accidentally introducing breaking changes. This is recommended for production environments to ensure safer agent deployments.

- version=`MAJOR_VERSION.MINOR_VERSION.PATCH_VERSION`
  - This setting is not recommended since it prevents upgrades of new versions of the agent that include bug fixes and other improvements.

### Example:

An example implementation can be found in [example/manifests/ops_agent.pp](example/manifests/ops_agent.pp)

#### Ops Agent

Install the latest version:
```ruby
google_cloud_ops::agent {'ops-agent':
  agent_type  => 'ops-agent',
}
```

#### Ops Agent with Custom Configuration

This example assumes:
- The module's name is `example`
- The module `example` has a file at `files/ops_agent/config.yaml` that represents the custom configuration

Install version 1.0.5 and use a custom configuration:
```ruby
google_cloud_ops::agent {'ops-agent':
  agent_type  => 'ops-agent',
  installed   => true,
  version     => '1.0.5',
  main_config => 'puppet:///modules/example/ops_agent/config.yaml',
}
```

#### Remove Ops Agent

Ensure the agent is not installed by setting `installed` to false:
```ruby
google_cloud_ops::agent {'ops-agent':
  agent_type  => 'ops-agent',
  installed   => false,
  version     => 'latest',
}
```

#### Install Monitoring Agent

- Install latest release of major version 6
- Use custom configuration
- Use custom plugins

```ruby
google_cloud_ops::agent {'monitoring-agent':
  agent_type            => 'monitoring',
  installed             => true,
  version               => '6.*.*',

  # optional
  main_config           => 'puppet:///modules/example/monitoring/collectd.conf',
  additional_config_dir => 'puppet:///modules/example/monitoring/plugins'
}
```

#### Install Logging Agent

- Install latest release
- Use custom configuration
- Use custom plugins

```ruby
google_cloud_ops::agent {'logging-agent':
  agent_type            => 'logging',
  installed             => true,
  version               => 'latest',

  # optional
  main_config           => 'puppet:///modules/example/logging/google-fluentd.conf',
  additional_config_dir => 'puppet:///modules/example/logging/plugins'
}
```

## License

```
Copyright 2021 Google Inc. All rights reserved.

Licensed under the Apache License, Version 2.0 (the "License"); you may not use
this file except in compliance with the License.  You may obtain a copy of the
License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied.  See the License for the
specific language governing permissions and limitations under the License.
```
