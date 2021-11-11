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
  name = "${var.app_name~} ${terraform.workspace == "prod" ? "" : "-${terraform.workspace}"}"
  value = google_compute_address.ingress_ip_address.address
  type = "A"
  proxied = true
}