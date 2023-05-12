variable "prefix" {
  type        = string
  default = "drone01"
  description = "A prefix used for all resources"
}

variable "resource_group_name" {
  type        = string
  default     = "demo"
  description = "Name of ressource groupe"
}

variable "location" {
  type        = string
  default     = "westeurope"
  description = "The Azure Region in which all resources should be provisioned"
}

variable "env" {
  type        = string
  default = "prod"
  description = "The Work Environment"
}

variable "k8sversion" {
  type        = string
  default     = "1.26.3"
  description = "The version of Kubernetes"
}

variable "vm_type" {
  type        = string
  default     = "Standard_B2ms"
  description = "The virtual machine sizes"
}
