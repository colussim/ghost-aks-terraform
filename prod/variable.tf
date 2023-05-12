variable "selectors" {
  type = map(string)
  default = {}
}

variable "labels" {
  type = map(string)
  default = {}
}
variable "dep_name" {
  default     = "ghost-deployment01"
  description = "The name of the Ghost deployment"
}
variable "target_ns_add" {
  type        = bool
  default     = true
  description = "0:FALSE not create namespace 1:TRUE create namespace"
}

variable "target_sc_add" {
  type        = bool
  default     = true
  description = "0:FALSE not create storage class 1:TRUE create namespace"
}

variable "storage_class" {
  default     = "ghost-sc"
  description = "The name of the Ghost storage_class"
}

variable "ghost_namespace" {
  type        = string
  default     = "ghost"
  description = "Name of Ghost namespace"
}

variable "sc_location" {
  type        = string
  default     = "westeurope"
  description = "Storage Location"
}

variable "ghost_pvc" {
  type        = string
  default     = "ghost-pvc"
  description = "Ghost PVC Name"
}

variable "ghost_pvc_size" {
  type        = string  
  default     = "10Gi"
  description = "The storage size of the Ghost PVC"
}

variable "ghost_cont_name" {
  type        = string
  default = "ghost"
  description = "The container name"
}

variable "ghost_image_url" {
  type        = string
  default = "ghost"
  description = "The image url of the Ghostl version wanted"
}

variable "ghost_image_tag" {
  type        = string
  default = "latest"
  description = "The image tag of the Ghost version wanted"
}

variable "ghost_port" {
  type        = number
  description = "Port to open on the container and the public IP address."
  default     = 2368
}

variable "ghost_cpu_cores" {
  type        = string
  description = "The number of CPU cores to allocate to the container."
  default     = "2.0"
}

variable "ghost_memory" {
  type        = string
  description = "The amount of memory to allocate to the container in gigabytes."
  default     = "2Gi"
}

variable "adminpassword" {
  type        = string
  default     = "Bench123"
  description = "MySQL Admin password"
}

variable "adminuser" {
  type        = string
  default     = "adminghost"
  description = "Admin user"
}
variable "hostdb" {
  type        = string
  default     = "mysqlfs-ghost01drone.mysql.database.azure.com" 
  description = "Host database"
}

variable "db" {
  type        = string
  default     = "ghost"
  description = "ghost database name"
}

variable "input_file" {
  type        = string
  default     = "../database/certificates/DigiCertGlobalRootCA.crt.pem"
  description = "MySQL ssl certificate"
}

variable "url_site" {
  type        = string
  default     = "ghost01.droneshuttles.com"
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