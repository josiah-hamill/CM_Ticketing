output "endpoint" {
  value = google_container_cluster.cluster.endpoint
  sensitive = true
}

output "cluster_ca_certificate" {
  value = google_container_cluster.cluster.master_auth[0].cluster_ca_certificate
  sensitive = true
}