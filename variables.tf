variable "project_id" {
  description = "Google Cloud project that owns the workload."
  type        = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id must be a valid Google Cloud project ID."
  }
}

variable "region" {
  description = "Region for all regional resources."
  type        = string
  default     = "us-central1"
  validation {
    condition     = can(regex("^[a-z]+-[a-z]+[0-9]$", var.region))
    error_message = "region must be a Google Cloud region name."
  }
}

variable "name" {
  description = "Lowercase workload name used in resource names."
  type        = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,28}[a-z0-9]$", var.name))
    error_message = "name must contain 3 to 30 lowercase letters, digits, or hyphens."
  }
}

variable "image" {
  description = "Container image URL pinned by sha256 digest."
  type        = string
  validation {
    condition     = can(regex("^[^[:space:]@]+@sha256:[0-9a-f]{64}$", var.image))
    error_message = "image must use an immutable sha256 digest."
  }
}

variable "network_id" {
  description = "Full resource ID of an existing VPC with private service access configured."
  type        = string
  validation {
    condition     = can(regex("^projects/[^/]+/global/networks/[^/]+$", var.network_id))
    error_message = "network_id must be a full projects/.../global/networks/... resource ID."
  }
}

variable "database_tier" {
  description = "Cloud SQL machine tier. Review regional pricing before changing it."
  type        = string
  default     = "db-custom-2-7680"
  validation {
    condition     = startswith(var.database_tier, "db-")
    error_message = "database_tier must be a Cloud SQL db-* tier."
  }
}

variable "database_version" {
  description = "Cloud SQL PostgreSQL major version."
  type        = string
  default     = "POSTGRES_17"
  validation {
    condition     = contains(["POSTGRES_16", "POSTGRES_17", "POSTGRES_18"], var.database_version)
    error_message = "database_version must be a supported PostgreSQL version."
  }
}

variable "deletion_protection" {
  description = "Protect the database from Terraform deletion. Disable only during a reviewed teardown."
  type        = bool
  default     = true
}

variable "min_instances" {
  description = "Minimum Cloud Run instances. Zero reduces idle cost but permits cold starts."
  type        = number
  default     = 1
  validation {
    condition     = var.min_instances >= 0 && var.min_instances <= 10 && floor(var.min_instances) == var.min_instances
    error_message = "min_instances must be an integer from 0 through 10."
  }
}

variable "max_instances" {
  description = "Maximum Cloud Run instances and primary database connection-budget control."
  type        = number
  default     = 10
  validation {
    condition     = var.max_instances >= 1 && var.max_instances <= 100 && floor(var.max_instances) == var.max_instances
    error_message = "max_instances must be an integer from 1 through 100."
  }
}

variable "container_port" {
  description = "Application HTTP port."
  type        = number
  default     = 8080
  validation {
    condition     = var.container_port >= 1024 && var.container_port <= 65535
    error_message = "container_port must be between 1024 and 65535."
  }
}
