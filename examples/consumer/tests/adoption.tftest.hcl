mock_provider "google" {}

run "consumer_adoption" {
  command = plan

  assert {
    condition     = output.capacity.min_instances == 2 && output.capacity.max_instances == 12
    error_message = "The consumer must preserve its reviewed instance range."
  }

  assert {
    condition     = output.capacity.request_concurrency == 20
    error_message = "The consumer must preserve its database-aware concurrency limit."
  }

  assert {
    condition     = google_secret_manager_secret_iam_member.orders.role == "roles/secretmanager.secretAccessor"
    error_message = "The consumer must grant only secret payload access to the runtime identity."
  }
}
