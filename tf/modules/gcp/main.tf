locals {
  name_prefix = "${var.project_name}-${var.environment}"
  
  common_labels = merge(
    var.tags,
    {
      project     = var.project_name
      environment = var.environment
    }
  )

  # Get project ID from provider
  project_id = data.google_project.current.project_id
}

data "google_project" "current" {}

# VPC Network
resource "google_compute_network" "main" {
  name                    = "${local.name_prefix}-vpc"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"

  labels = local.common_labels
}

# Public Subnets
resource "google_compute_subnetwork" "public" {
  count         = length(var.public_subnet_cidrs)
  name          = "${local.name_prefix}-public-subnet-${count.index + 1}"
  ip_cidr_range = var.public_subnet_cidrs[count.index]
  region        = var.region
  network       = google_compute_network.main.id

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
  }
}

# Private Subnets
resource "google_compute_subnetwork" "private" {
  count         = length(var.private_subnet_cidrs)
  name          = "${local.name_prefix}-private-subnet-${count.index + 1}"
  ip_cidr_range = var.private_subnet_cidrs[count.index]
  region        = var.region
  network       = google_compute_network.main.id
  private_ip_google_access = true

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
  }
}

# Cloud Router for NAT
resource "google_compute_router" "main" {
  count   = length(google_compute_subnetwork.private)
  name    = "${local.name_prefix}-router-${count.index + 1}"
  region  = var.region
  network = google_compute_network.main.id

  bgp {
    asn = 64514
  }
}

# Cloud NAT for Private Subnets
resource "google_compute_router_nat" "main" {
  count                              = length(google_compute_router.main)
  name                               = "${local.name_prefix}-nat-${count.index + 1}"
  router                             = google_compute_router.main[count.index].name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Firewall Rule: Allow SSH from Internet to Public Subnet
resource "google_compute_firewall" "public_ssh" {
  name    = "${local.name_prefix}-public-ssh"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["jumphost"]
}

# Firewall Rule: Allow All Outbound from Public Subnet
resource "google_compute_firewall" "public_egress" {
  name      = "${local.name_prefix}-public-egress"
  network   = google_compute_network.main.name
  direction = "EGRESS"

  allow {
    protocol = "all"
  }

  target_tags = ["jumphost"]
  destination_ranges = ["0.0.0.0/0"]
}

# Firewall Rule: Allow SSH from Public Subnet to Private Subnet
resource "google_compute_firewall" "private_ssh_from_public" {
  name    = "${local.name_prefix}-private-ssh-from-public"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_tags   = ["jumphost"]
  target_tags   = ["private-vm"]
  source_ranges = [var.public_subnet_cidrs[0]]
}

# Firewall Rule: Allow All Traffic within VPC
resource "google_compute_firewall" "vpc_internal" {
  name    = "${local.name_prefix}-vpc-internal"
  network = google_compute_network.main.name

  allow {
    protocol = "all"
  }

  source_ranges = [var.vpc_cidr]
  target_tags   = ["private-vm"]
}

# Firewall Rule: Allow All Outbound from Private Subnet
resource "google_compute_firewall" "private_egress" {
  name      = "${local.name_prefix}-private-egress"
  network   = google_compute_network.main.name
  direction = "EGRESS"

  allow {
    protocol = "all"
  }

  target_tags = ["private-vm"]
  destination_ranges = ["0.0.0.0/0"]
}

# Generate SSH key pair if not provided
resource "tls_private_key" "jumphost_key" {
  count     = var.jumphost_ssh_key == "" ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Store SSH key in project metadata
resource "google_compute_project_metadata_item" "ssh_keys" {
  count   = var.enable_jumphost ? 1 : 0
  key     = "ssh-keys"
  value   = var.jumphost_ssh_key != "" ? "terraform:${var.jumphost_ssh_key}" : "terraform:${tls_private_key.jumphost_key[0].public_key_openssh}"
  project = local.project_id
}

# Get latest Ubuntu image
data "google_compute_image" "ubuntu" {
  family  = "ubuntu-2204-lts"
  project = "ubuntu-os-cloud"
}

# Jumphost Instance in Public Subnet
resource "google_compute_instance" "jumphost" {
  count        = var.enable_jumphost ? 1 : 0
  name         = "${local.name_prefix}-jumphost"
  machine_type = var.jumphost_machine_type
  zone         = "${var.region}-a"

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
    }
  }

  network_interface {
    network    = google_compute_network.main.name
    subnetwork = google_compute_subnetwork.public[0].id

    access_config {
      // Ephemeral public IP
    }
  }

  tags = ["jumphost"]

  labels = local.common_labels

  metadata = {
    enable-oslogin = "TRUE"
  }

  service_account {
    email  = google_service_account.jumphost[0].email
    scopes = ["cloud-platform"]
  }
}

# Private VM Instance
resource "google_compute_instance" "private_vm" {
  count        = var.enable_private_vm ? 1 : 0
  name         = "${local.name_prefix}-private-vm"
  machine_type = var.private_vm_machine_type
  zone         = "${var.region}-a"

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
    }
  }

  network_interface {
    network    = google_compute_network.main.name
    subnetwork = google_compute_subnetwork.private[0].id
    // No access_config = private IP only
  }

  tags = ["private-vm"]

  labels = local.common_labels

  metadata = {
    enable-oslogin = "TRUE"
  }

  service_account {
    email  = google_service_account.private_vm[0].email
    scopes = ["cloud-platform"]
  }
}

# Service Account for Jumphost
resource "google_service_account" "jumphost" {
  count        = var.enable_jumphost ? 1 : 0
  account_id   = "${replace(local.name_prefix, "-", "")}-jh-sa"
  display_name = "Jumphost Service Account"
}

# Service Account for Private VM
resource "google_service_account" "private_vm" {
  count        = var.enable_private_vm ? 1 : 0
  account_id   = "${replace(local.name_prefix, "-", "")}-pv-sa"
  display_name = "Private VM Service Account"
}

