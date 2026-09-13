terraform {
  required_version = ">= 1.11, < 2.0"
}

module "orders" {
  source = "../.."

  project_id = "example-platform-123"
  region     = "us-central1"
  name       = "orders"
  network_id = "projects/example-platform-123/global/networks/private"
  image      = "us-central1-docker.pkg.dev/example-platform-123/orders/app@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
}
