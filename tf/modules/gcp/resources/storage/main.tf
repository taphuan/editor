resource "google_storage_bucket" "storage" {
  name          = var.name
  location      = var.location
  project       = var.project_id
  storage_class = var.storage_class

  versioning {
    enabled = var.versioning
  }

  uniform_bucket_level_access = true

  encryption {
    default_kms_key_name = null
  }

  labels = var.labels
}

