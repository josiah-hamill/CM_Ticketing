terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "~> 4.0"
    }
    helm = {
      source = "hashicorp/helm"
      version = "2.4.1"
    }
  }
  backend "gcs" {
    bucket = "ticketing-devops-hamill-terraform"
    prefix = "/state/ticketing/lb"
  }
}

data "terraform_remote_state" "cluster" {
  backend = "gcs" 
  config = {
    bucket = "ticketing-devops-hamill-terraform"
    prefix = "/state/ticketing/cluster"
  }
  workspace = "${terraform.workspace}"
}

provider "google" {
  credentials = file("../terraform-sa-key.json")
  project = var.gcp_project_name
  region = var.gcp_project_region
  zone = var.gcp_project_zone
}

data "google_service_account_access_token" "cluster_sa" {
  target_service_account = "terraform-sa@ticketing-devops-hamill.iam.gserviceaccount.com"
  scopes                 = ["userinfo-email", "cloud-platform"]
  lifetime               = "3600s"
}

provider "helm" {
  kubernetes {
    host  = "https://${data.terraform_remote_state.cluster.outputs.endpoint}"
    token = data.google_service_account_access_token.cluster_sa.access_token
    cluster_ca_certificate = base64decode(
      data.terraform_remote_state.cluster.outputs.cluster_ca_certificate
    )
  }
}

resource "helm_release" "ingress-nginx" {
  name = "ingress-nginx"
  chart = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  namespace = "ingress-nginx"
  create_namespace = true

  set {
    name = "controller.service.loadBalancerIP"
    value = "35.238.10.191"
  }
}

resource "helm_release" "ingress-srv-gcp" {
  name = "ingress-srv-gcp"
  chart = "../../infra/ingress-srv-gcp"
}

resource "helm_release" "ticketing-cluster" {
  name = "ticketing-cluster"
  chart = "../../infra/ticketing-cluster"
  timeout = 1800
  set_sensitive {
    name = "JWT_KEY"
    value = var.jwt_key
  }
  set_sensitive {
    name = "STRIPE_KEY"
    value = var.stripe_key
  }
}