output "repository_url" {
  description = "Artifact Registry Docker repository prefix."
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.app.repository_id}"
}

output "service_name" {
  description = "Cloud Run service name."
  value       = google_cloud_run_v2_service.app.name
}

output "service_uri" {
  description = "Cloud Run URI. Access remains restricted by ingress and IAM."
  value       = google_cloud_run_v2_service.app.uri
}

output "runtime_service_account" {
  description = "Runtime identity for application-specific IAM grants."
  value       = google_service_account.app.email
}

output "database_connection_name" {
  description = "Cloud SQL connection name used by the Cloud Run volume."
  value       = google_sql_database_instance.app.connection_name
}
