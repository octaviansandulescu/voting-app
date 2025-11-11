###############################################################################
# TERRAFORM VARIABLES
###############################################################################

variable "project_id" {
  description = "GCP Project ID"
  type        = string
  default     = "diesel-skyline-474415-j6"
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "cluster_name" {
  description = "GKE Cluster name"
  type        = string
  default     = "voting-app-cluster"
}

variable "database_name" {
  description = "Cloud SQL database name"
  type        = string
  default     = "voting_app_k8s"
}

variable "database_user" {
  description = "Cloud SQL database user"
  type        = string
  default     = "voting_user"
}

variable "node_count" {
  description = "Number of GKE nodes"
  type        = number
  default     = 3
}
