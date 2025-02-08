provider "google" {
  project = var.project_id
  region  = "us-central1"
}

# Generate random suffix for unique names
resource "random_id" "suffix" {
  byte_length = 4
}

# Service Account for Cloud SQL Access
resource "google_service_account" "ghost_service_account" {
  account_id   = "ghost-sa-${random_id.suffix.hex}"
  display_name = "Ghost Service Account"
}

# Grant IAM Roles to Service Account
resource "google_project_iam_member" "cloudsql_admin" {
  project = var.project_id
  role    = "roles/cloudsql.admin"
  member  = "serviceAccount:${google_service_account.ghost_service_account.email}"
}

resource "google_project_iam_member" "service_account_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.ghost_service_account.email}"
}

# Cloud SQL Database Instance
resource "google_sql_database_instance" "ghost_db" {
  name             = "ghost-db-${random_id.suffix.hex}"
  database_version = "MYSQL_8_0"
  
  # Ensure IAM permissions are applied before creating the instance
  depends_on = [
    google_project_iam_member.cloudsql_admin,
    google_project_iam_member.service_account_user
  ]

  settings {
    tier = "db-g1-small"
    ip_configuration {
      ipv4_enabled    = true
      authorized_networks {
        value = var.whitelist_ip
      }
    }
  }
}

resource "google_sql_database" "ghost" {
  name     = "ghost"
  instance = google_sql_database_instance.ghost_db.name
}

resource "google_sql_user" "ghost_user" {
  name     = "ghost_user"
  password = var.db_password
  instance = google_sql_database_instance.ghost_db.name
}

# Compute Engine VM
resource "google_compute_instance" "ghost_instance" {
  name         = "ghost-instance-${random_id.suffix.hex}"
  machine_type = "e2-medium"
  zone         = "us-central1-c"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${var.ssh_public_key}"
  }

  service_account {
    email  = google_service_account.ghost_service_account.email
    scopes = ["cloud-platform"]
  }
}

# Firewall Rules
resource "google_compute_firewall" "ssh" {
  name    = "allow-ssh-${random_id.suffix.hex}"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.whitelist_ip]
}

resource "google_compute_firewall" "ghost" {
  name    = "allow-ghost-${random_id.suffix.hex}"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["2368"]
  }

  source_ranges = ["0.0.0.0/0"]
}

output "instance_external_ip" {
  value = google_compute_instance.ghost_instance.network_interface[0].access_config[0].nat_ip
}

output "cloudsql_ip" {
  value = google_sql_database_instance.ghost_db.public_ip_address
}
