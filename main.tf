locals {
  labels = {
    managed-by = "terraform"
    workload   = var.name
  }
}

resource "google_artifact_registry_repository" "app" {
  project       = var.project_id
  location      = var.region
  repository_id = var.name
  description   = "Immutable application images for ${var.name}"
  format        = "DOCKER"
  mode          = "STANDARD_REPOSITORY"
  labels        = local.labels

  docker_config {
    immutable_tags = true
  }

  cleanup_policy_dry_run = true
  cleanup_policies {
    id     = "retain-recent"
    action = "KEEP"
    most_recent_versions {
      keep_count = 20
    }
  }
}

resource "google_service_account" "app" {
  project      = var.project_id
  account_id   = substr("${var.name}-runtime", 0, 30)
  display_name = "${var.name} Cloud Run runtime"
}

resource "google_project_iam_member" "cloudsql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.app.email}"
}

resource "google_project_iam_member" "cloudsql_instance_user" {
  project = var.project_id
  role    = "roles/cloudsql.instanceUser"
  member  = "serviceAccount:${google_service_account.app.email}"
}

resource "google_sql_database_instance" "app" {
  project             = var.project_id
  region              = var.region
  name                = "${var.name}-postgres"
  database_version    = var.database_version
  deletion_protection = var.deletion_protection

  settings {
    tier                        = var.database_tier
    availability_type           = "REGIONAL"
    disk_type                   = "PD_SSD"
    disk_size                   = 20
    disk_autoresize             = true
    disk_autoresize_limit       = 200
    deletion_protection_enabled = true
    user_labels                 = local.labels

    backup_configuration {
      enabled                        = true
      point_in_time_recovery_enabled = true
      start_time                     = "03:00"
      transaction_log_retention_days = 7
      backup_retention_settings {
        retained_backups = 14
        retention_unit   = "COUNT"
      }
    }

    database_flags {
      name  = "cloudsql.iam_authentication"
      value = "on"
    }

    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = var.network_id
      enable_private_path_for_google_cloud_services = true
      ssl_mode                                      = "ENCRYPTED_ONLY"
    }

    maintenance_window {
      day          = 7
      hour         = 4
      update_track = "stable"
    }

    insights_config {
      query_insights_enabled  = true
      query_string_length     = 1024
      record_application_tags = true
      record_client_address   = false
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_sql_database" "app" {
  project  = var.project_id
  instance = google_sql_database_instance.app.name
  name     = "app"
}

resource "google_sql_user" "app" {
  project  = var.project_id
  instance = google_sql_database_instance.app.name
  name     = trimsuffix(google_service_account.app.email, ".gserviceaccount.com")
  type     = "CLOUD_IAM_SERVICE_ACCOUNT"
}

resource "google_cloud_run_v2_service" "app" {
  project             = var.project_id
  location            = var.region
  name                = var.name
  ingress             = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
  deletion_protection = true

  template {
    service_account                  = google_service_account.app.email
    labels                           = local.labels
    timeout                          = "30s"
    max_instance_request_concurrency = 80

    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }

    containers {
      image = var.image

      ports {
        container_port = var.container_port
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
        cpu_idle          = true
        startup_cpu_boost = false
      }

      env {
        name  = "DB_NAME"
        value = google_sql_database.app.name
      }
      env {
        name  = "DB_USER"
        value = google_sql_user.app.name
      }
      env {
        name  = "DB_SOCKET"
        value = "/cloudsql/${google_sql_database_instance.app.connection_name}"
      }

      volume_mounts {
        name       = "cloudsql"
        mount_path = "/cloudsql"
      }

      startup_probe {
        failure_threshold     = 12
        initial_delay_seconds = 0
        period_seconds        = 5
        timeout_seconds       = 2
        http_get {
          path = "/health/live"
          port = var.container_port
        }
      }
      liveness_probe {
        failure_threshold = 3
        period_seconds    = 10
        timeout_seconds   = 2
        http_get {
          path = "/health/live"
          port = var.container_port
        }
      }
    }

    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [google_sql_database_instance.app.connection_name]
      }
    }

    vpc_access {
      egress = "PRIVATE_RANGES_ONLY"
      network_interfaces {
        network = var.network_id
      }
    }
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }

  depends_on = [
    google_project_iam_member.cloudsql_client,
    google_project_iam_member.cloudsql_instance_user,
  ]
}
