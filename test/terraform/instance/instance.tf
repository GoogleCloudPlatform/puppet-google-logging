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
  description = "Google Cloud Project"
  type        = string
}

variable "source_image" {
  description = "Source image"
  type        = string
}

variable "instance_type" {
  description = "Instance Type"
  type        = string
  default     = "e2-medium"
}

variable "zone" {
  description = "Google Compute zone"
  type        = string
  default     = "us-east1-b"
}

variable "preemptible" {
  description = "Google Compute zone"
  type        = bool
  default     = false
}

variable "ssh_public_key" {
  description = "File path to ssh public key"
  default     = "~/.ssh/id_rsa.pub"
}

resource "google_compute_instance" "instance" {
  project      = var.project
  name         = terraform.workspace
  machine_type = var.instance_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.source_image
    }
  }

  network_interface {
    network = "default"
    access_config {
      // dynamic public ip
    }
  }

  metadata = {
    used_by   = "github-actions"
    workspace = terraform.workspace
    ssh-keys  = "ci:${file(var.ssh_public_key)}"
  }

  scheduling {
    preemptible       = var.preemptible
    automatic_restart = var.preemptible == true ? false : true
  }

  service_account {
    scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/monitoring"
    ]
  }
}