data "google_compute_image" "ubuntu" {
  family  = "ubuntu-2204-lts"
  project = "ubuntu-os-cloud"
}

resource "google_compute_instance" "vm" {
  name         = var.name
  machine_type = var.machine_type
  zone         = var.zone
  project      = var.project_id

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
    }
  }

  network_interface {
    network    = var.network
    subnetwork = var.subnetwork

    dynamic "access_config" {
      for_each = var.public_ip ? [1] : []
      content {
        // Ephemeral public IP
      }
    }
  }

  tags   = var.tags
  labels = var.labels

  metadata = {
    enable-oslogin = "TRUE"
    ssh-keys       = "terraform:${var.ssh_public_key}"
  }
}

