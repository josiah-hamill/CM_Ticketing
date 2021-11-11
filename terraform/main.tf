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
    helm = {
      source = "hashicorp/helm"
      version = "2.4.1"
    }
  }
  backend "gcs" {
    bucket = "ticketing-devops-hamill-terraform"
    prefix = "/state/ticketing"
  }
}

provider "google" {
  credentials = file("terraform-sa-key.json")
  project = var.gcp_project_name
  region = var.gcp_project_region
  zone = var.gcp_project_zone
}

module "cluster" {
  source = "./modules/cluster"
  app_name = var.app_name
  gcp_project_name = var.gcp_project_name
  gcp_project_region = var.gcp_project_region
  gcp_project_zone = var.gcp_project_zone
  gcp_machine_type = var.gcp_machine_type
}

data "google_service_account_access_token" "cluster_sa" {
  target_service_account = "terraform-sa@ticketing-devops-hamill.iam.gserviceaccount.com"
  scopes                 = ["userinfo-email", "cloud-platform"]
  lifetime               = "3600s"
}

data "google_container_cluster" "cluster" {
  name     = "${var.app_name}-${terraform.workspace}"
  location = "${var.gcp_project_zone}"
}

provider "helm" {
  kubernetes {
    host  = "https://${data.google_container_cluster.cluster.endpoint}"
    token = data.google_service_account_access_token.cluster_sa.access_token
    cluster_ca_certificate = base64decode(
      data.google_container_cluster.cluster.master_auth[0].cluster_ca_certificate,
    )
  }
}

module "ingress" {
  source = "./modules/ingress"
  depends_on = [
    module.cluster
  ]
}

module "pods" {
  source = "./modules/pods"
  depends_on = [
    module.ingress
  ]
}