variable "location" {
  type        = string
  default     = "westeurope"
  description = "The Azure Region in which all resources should be provisioned"
}

variable "resource_group_name" {
  type        = string
  default     = "demo"
  description = "Name of ressource groupe"
}

variable "db_hostname" {
  default     = "ghost01drone"
  description = "The virtual machine hostname"
}

variable "virtual_netname" {
  default     = "drone01-network"
  description = "Virtual network name how run AKS"
}

variable "subnet_name" {
  default     = "db-mysql01"
  description = "Subnet network DB name"
}

variable "adminpassword" {
  default     = "Bench123"
  description = "MySQL Admin password"
}

variable "adminuser" {
  default     = "adminghost"
  description = "Admin user"
}

#variable "vm_type" {
 # default     = "GP_Standard_D2ds_v4"
  #description = "The virtual machine sizes"
#}

variable "vm_type" {
  default     = "GP_Standard_D2ads_v5"
  description = "The virtual machine sizes"
}