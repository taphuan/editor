resource "google_secret_manager_secret" "vault" {
  secret_id = var.name
  project   = var.project_id

  replication {
    auto {}
  }

  labels = var.labels
}

