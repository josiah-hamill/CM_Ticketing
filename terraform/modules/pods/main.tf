resource "helm_release" "pods" {
  name = "ticketing-cluster"
  chart = "../infra/ticketing-cluster"
}