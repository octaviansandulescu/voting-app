###############################################################################
# TERRAFORM - GKE CLUSTER + CLOUD SQL FOR VOTING APP
# 
# This creates:
# 1. GKE Cluster (Kubernetes) with 3 nodes
# 2. Cloud SQL MySQL instance
# 3. VPC and networking
# 4. Service accounts and IAM
#
# AUTHENTICATION:
# - Set GOOGLE_APPLICATION_CREDENTIALS environment variable to service account JSON
# - Or use: gcloud auth application-default login
# - Or export GCP_CREDENTIALS=/path/to/key.json (handled by start-deployment.sh)
###############################################################################

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

# Provider auto-detects credentials from:
# 1. GOOGLE_APPLICATION_CREDENTIALS environment variable (set by start-deployment.sh)
# 2. gcloud Application Default Credentials
# 3. Service account attached to compute instance
provider "google" {
  project = var.project_id
  region  = var.region
}

# NOTE: Required APIs must be enabled manually or by an admin before running terraform
# This is because service account typically has minimal permissions for security
# Enable APIs with: gcloud services enable container.googleapis.com sqladmin.googleapis.com compute.googleapis.com servicenetworking.googleapis.com

# ============================================================================
# VPC Network
# ============================================================================

resource "google_compute_network" "voting_vpc" {
  name                    = "${var.cluster_name}-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "voting_subnet" {
  name          = "${var.cluster_name}-subnet"
  ip_cidr_range = "10.0.0.0/16"
  region        = var.region
  network       = google_compute_network.voting_vpc.id

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.4.0.0/14"
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.8.0.0/20"
  }
}

# Private service connection for Cloud SQL
# NOTE: Private VPC peering disabled - using public IP for simplicity
# Uncomment below if you want private IP access to Cloud SQL (requires servicenetworking.admin role)
# resource "google_compute_global_address" "private_ip_address" {
#   name          = "${var.cluster_name}-private-ip"
#   purpose       = "VPC_PEERING"
#   address_type  = "INTERNAL"
#   prefix_length = 16
#   network       = google_compute_network.voting_vpc.id
# }

# resource "google_service_networking_connection" "private_vpc_connection" {
#   network                 = google_compute_network.voting_vpc.id
#   service                 = "servicenetworking.googleapis.com"
#   reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
# }

# ============================================================================
# Cloud SQL MySQL Instance
# ============================================================================

resource "google_sql_database_instance" "voting_db" {
  name             = "${var.cluster_name}-db"
  database_version = "MYSQL_8_0"
  region           = var.region
  deletion_protection = false

  settings {
    tier      = "db-f1-micro"
    disk_size = 20

    backup_configuration {
      enabled = true
    }

    ip_configuration {
      # Use public IP for simplicity (can access from GKE via network)
      ipv4_enabled = true
      # Don't require SSL for simplicity (can enable later)
      # require_ssl is deprecated - use ssl_mode instead
      
      # Allow connections from any IP (for simplicity, can be restricted later)
      authorized_networks {
        name  = "allow-all"
        value = "0.0.0.0/0"
      }
    }
  }
}

resource "google_sql_database" "voting_db" {
  name     = var.database_name
  instance = google_sql_database_instance.voting_db.name
}

resource "google_sql_user" "voting_db_user" {
  name     = var.database_user
  instance = google_sql_database_instance.voting_db.name
  password = random_password.db_password.result
}

resource "random_password" "db_password" {
  length  = 32
  special = true
}

# ============================================================================
# GKE Cluster
# ============================================================================

resource "google_container_cluster" "voting_cluster" {
  name     = var.cluster_name
  location = var.region

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.voting_vpc.name
  subnetwork = google_compute_subnetwork.voting_subnet.name

  networking_mode = "VPC_NATIVE"

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  addons_config {
    http_load_balancing {
      disabled = false
    }
  }
}

# ============================================================================
# GKE Node Pool
# ============================================================================

resource "google_container_node_pool" "voting_nodes" {
  name       = "${var.cluster_name}-node-pool"
  location   = var.region
  cluster    = google_container_cluster.voting_cluster.name
  node_count = var.node_count

  autoscaling {
    min_node_count = 2
    max_node_count = 5
  }

  node_config {
    preemptible  = true
    machine_type = "e2-medium"

    disk_size_gb = 20
    disk_type    = "pd-standard"

    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/servicecontrol"
    ]
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

# ============================================================================
# Firewall Rule - Allow GKE nodes to Cloud SQL
# ============================================================================

resource "google_compute_firewall" "allow_gke_to_cloudsql" {
  name    = "${var.cluster_name}-allow-to-cloudsql"
  network = google_compute_network.voting_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["3306"]
  }

  # Allow traffic from GKE nodes (all nodes in this VPC)
  source_ranges = ["10.0.0.0/8"]  # VPC CIDR range for cluster nodes
  
  target_tags = ["gke-node"]
}

# ============================================================================
# Outputs
# ============================================================================

output "kubernetes_cluster_name" {
  value       = google_container_cluster.voting_cluster.name
  description = "GKE Cluster Name"
}

output "kubernetes_cluster_host" {
  value       = google_container_cluster.voting_cluster.endpoint
  description = "GKE Cluster Host"
  sensitive   = true
}

output "region" {
  value       = var.region
  description = "GCP region"
}

output "sql_instance_connection_name" {
  value       = google_sql_database_instance.voting_db.connection_name
  description = "Cloud SQL connection name for K8s"
}

output "sql_database_name" {
  value       = google_sql_database.voting_db.name
  description = "Database name"
}

output "sql_database_user" {
  value       = google_sql_user.voting_db_user.name
  description = "Database user"
}

output "sql_database_password" {
  value       = random_password.db_password.result
  description = "Database password"
  sensitive   = true
}

output "sql_instance_ip" {
  value       = google_sql_database_instance.voting_db.private_ip_address != null ? google_sql_database_instance.voting_db.private_ip_address : google_sql_database_instance.voting_db.public_ip_address
  description = "Database IP address"
}
