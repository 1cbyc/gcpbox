mock_provider "google" {}

variables {
  project_id = "valid-project-123"
  region     = "us-central1"
  name       = "orders"
  image      = "us-central1-docker.pkg.dev/valid-project-123/orders/app@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  network_id = "projects/valid-project-123/global/networks/private"
}

run "secure_foundation" {
  command = plan

  assert {
    condition     = google_artifact_registry_repository.app.docker_config[0].immutable_tags
    error_message = "Artifact Registry tags must be immutable."
  }
  assert {
    condition     = google_sql_database_instance.app.settings[0].availability_type == "REGIONAL"
    error_message = "Cloud SQL must use regional availability."
  }
  assert {
    condition     = google_sql_database_instance.app.settings[0].ip_configuration[0].ipv4_enabled == false
    error_message = "Cloud SQL must not expose a public IPv4 address."
  }
  assert {
    condition     = google_sql_database_instance.app.settings[0].ip_configuration[0].ssl_mode == "ENCRYPTED_ONLY"
    error_message = "Cloud SQL must require encrypted connections."
  }
  assert {
    condition     = google_cloud_run_v2_service.app.ingress == "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
    error_message = "Cloud Run ingress must stay private or load-balancer-only."
  }
  assert {
    condition     = google_cloud_run_v2_service.app.template[0].vpc_access[0].egress == "PRIVATE_RANGES_ONLY"
    error_message = "Only private ranges should use VPC egress."
  }
}

run "reject_mutable_image" {
  command = plan
  variables { image = "us-central1-docker.pkg.dev/valid-project-123/orders/app:latest" }
  expect_failures = [var.image]
}

run "reject_invalid_scaling" {
  command = plan
  variables { max_instances = 0 }
  expect_failures = [var.max_instances]
}

run "reject_privileged_port" {
  command = plan
  variables { container_port = 80 }
  expect_failures = [var.container_port]
}
