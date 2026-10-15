terraform {
  required_version = ">= 1.11, < 2.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 8.7.0"
    }
  }
}

variable "application_secret_id" {
  description = "Existing Secret Manager secret used by the application."
  type        = string
  default     = "orders-api-key"
}

module "orders" {
  source = "../.."

  project_id = "example-platform-123"
  region     = "us-central1"
  name       = "orders"
  network_id = "projects/example-platform-123/global/networks/private"
  image      = "us-central1-docker.pkg.dev/example-platform-123/orders/app@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

  min_instances           = 2
  max_instances           = 12
  request_concurrency     = 20
  cpu                     = 2
  memory                  = "1Gi"
  startup_probe_path      = "/health/ready"
  liveness_probe_path     = "/health/live"
  request_timeout_seconds = 20
}

resource "google_secret_manager_secret_iam_member" "orders" {
  project   = "example-platform-123"
  secret_id = var.application_secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${module.orders.runtime_service_account}"
}

output "capacity" {
  value = module.orders.capacity
}
