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

### Cloudflare
variable cloudflare_api_token {
  type = string
  sensitive = true
}

variable domain {
 type = string
}