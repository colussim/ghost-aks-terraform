variable "selectors" {
  type = map(string)
  default = {}
}
variable "labels" {
  type = map(string)
  default = {}
}

variable "selectorsdb" {
  type = map(string)
  default = {}
}
variable "labelsdb" {
  type = map(string)
  default = {}
}

variable "counterenv" {
  type        = number
  description = "Number of Dev environment"
  default     = 1
}
variable "db_dep_name" {
  default     = "db-dev-deployment"
  description = "The name of DB deployment"
}
variable "dep_name" {
  default     = "ghost-dev-deployment"
  description = "The name of the Ghost deployment"
}
variable "target_ns_add" {
  type        = bool
  default     = true
  description = "FALSE not create namespace TRUE create namespace"
}

variable "target_sc_add" {
  type        = bool
  default     = true
  description = "FALSE not create storage class TRUE create namespace"
}

variable "storage_class" {
  type        = string
  default     = "ghostdev-sc"
  description = "The name of the Ghost storage_class"
}

variable "ghost_namespace" {
  type        = string
  default     = "dev-ghost"
  description = "Name of Ghost namespace"
}

variable "sc_location" {
  type        = string
  default     = "westeurope"
  description = "Storage Location"
}

variable "ghost_pvc" {
  type        = string
  default     = "dev-ghost-pvc"
  description = "Ghost PVC Name"
}

variable "db_pvc" {
  type        = string
  default     = "db-pvc-dev"
  description = "Database PVC Name"
}

variable "ghost_pvc_size" {
  type        = string  
  default     = "10Gi"
  description = "The storage size of the Ghost PVC"
}

variable "db_pvc_size" {
  type        = string  
  default     = "10Gi"
  description = "The storage size of the Ghost PVC"
}

variable "ghost_cont_name" {
  type        = string
  default = "ghost"
  description = "The container name"
}

variable "db_cont_name" {
  type        = string
  default = "mysql"
  description = "The MySQL container name"
}

variable "ghost_image_url" {
  type        = string
  default = "ghost"
  description = "The image url of the Ghost version wanted"
}

variable "ghost_image_tag" {
  type        = string
  default = "latest"
  description = "The image tag of the Ghost version wanted"
}

variable "db_image_url" {
  type        = string
  default = "mysql"
  description = "The image url of the MySQL version wanted"
}

variable "db_image_tag" {
  type        = string
  default = "8.0.33"
  description = "The image tag of the MySQL version wanted"
}

variable "ghost_port" {
  type        = number
  description = "Port to open on the container and the public IP address."
  default     = 2368
}

variable "db_port" {
  type        = number
  description = "Port to open on the container and the public IP address."
  default     = 3306
}

variable "ns_cpu_cores_request" {
  type        = string
  description = "The number of CPU cores to allocate to the namespace."
  default     = "2.0"
}

variable "ns_memory_request" {
  type        = string
  description = "The amount of memory to allocate to the namespace in gigabytes."
  default     = "2Gi"
}

variable "ns_cpu_cores_limit" {
  type        = string
  description = "The number of CPU cores to allocate to the namespace."
  default     = "3.0"
}

variable "ns_memory_limit" {
  type        = string
  description = "The amount of memory to allocate to the namespace in gigabytes."
  default     = "3Gi"
}

variable "adminpassword" {
  type        = string
  default     = "Bench123"
  description = "MySQL Admin password"
}

variable "adminuser" {
  type        = string
  default     = "root"
  description = "MySQL Admin user"
}

variable "db" {
  type        = string
  default     = "ghost"
  description = "ghost database name"
}


variable "url_host" {
  type        = string
  default     = "ghostdev"
  description = "host url name"
}

variable "url_site" {
  type        = string
  default     = ".droneshuttles.com"
  description = "URL blog site"
}

variable "secret_name"  {
  type        = string
  default     = "droneshuttles-com-cert-secret"
  description = "secret Name for Certificate"
}

variable "certif_name"  {
  type        = string
  default     = "droneshuttles-com-cert"
  description = "certif Name"
}

variable "domaine_name" {
  type        = string
  default     = "droneshuttles.com"
  description = "DNS Domaine"
}
variable "ca_name" {
  type        = string
  default     = "droneshuttles-ca-issuer"
  description = "CA Issuer name"
}

variable "ingress_loadb_ip" {
  type        = string
  default     = "20.238.184.3"
  description = "External ip adress for nginx-ingress service"
}