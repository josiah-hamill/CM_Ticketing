### GENERAL
variable app_name {
  type = string
}

### GCP
variable gcp_project_name {
  type = string
}

variable gcp_project_region {
  type = string
}

variable gcp_machine_type {
  type = string
}

variable gcp_project_zone {
  type = string
}

### Cluster variables
variable jwt_key {
  type = string
  sensitive = true
}

variable stripe_key {
  type = string
  sensitive = true
}
