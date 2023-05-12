
variable "ingress_namespace" {
  type        = string
  default     = "ingress-nginx"
  description = "Name of ingress namespace"
}

variable "certif_namespace" {
  type        = string
  default     = "cert-manager"
  description = "Name of certif namespace"
}

variable "certif_ClusterIssuer" {
  type        = string
  default     = "droneshuttles-ca-issuer"
  description = "Name of certif ClusterIssuer "
}

variable "certif_wait" {
  type        = number
  default     = 80
  description = "Time in second waiting for the certificat pods to be ready"
}