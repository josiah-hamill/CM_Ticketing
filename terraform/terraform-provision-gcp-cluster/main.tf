terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "~> 3.38"
    }
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
  }
  backend "gcs" {
    bucket = "ticketing-devops-hamill-terraform"
    prefix = "/state/ticketing/cluster"
  }
}

provider "google" {
  credentials = file("../terraform-sa-key.json")
  project = var.gcp_project_name
  region = var.gcp_project_region
  zone = var.gcp_project_zone
}

resource "google_container_cluster" "cluster" {
  name     = "${var.app_name}-${terraform.workspace}"
  location = "${var.gcp_project_zone}"

  remove_default_node_pool = true
  initial_node_count       = 5
}

resource "google_container_node_pool" "node-pool" {
  name       = "${var.app_name}-node-pool-${terraform.workspace}"
  location   = "${var.gcp_project_zone}"
  cluster    = google_container_cluster.cluster.name
  node_count = 5

  node_config {
    preemptible  = false
    machine_type = "${var.gcp_machine_type}"
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# ZONE
data "cloudflare_zones" "cf_zones" {
  filter {
    name = var.domain
  }
}

# DNS A RECORD
resource "cloudflare_record" "dns_record" {
  zone_id = data.cloudflare_zones.cf_zones.zones[0].id
  name = "ticketing${terraform.workspace == "prod" ? "" : "-${terraform.workspace}"}"
  value = "35.238.10.191"
  type = "A"
  proxied = true
}