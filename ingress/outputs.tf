output "ingress_lb_ip" {
  value = data.external.ingress_ldb.result["ipldb"]
}
