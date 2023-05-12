locals {
  labelsdb = merge(var.labelsdb, {
    app = "dbdev${var.counterenv}"
    deploymentName = var.dep_name
  })

  selectorsdb = merge(var.selectorsdb, {
    app = "dbdev${var.counterenv}"
    deploymentName = var.dep_name
  })
  labels = merge(var.labels, {
    app = "ghostdev${var.counterenv}"
    deploymentName = var.dep_name
  })

  selectors = merge(var.selectors, {
    app = "ghostdev${var.counterenv}"
    deploymentName = var.dep_name
  })
}

# Create Ghost Namespace
resource "kubernetes_namespace" "ghost_ns" {
  count ="${var.target_ns_add ? 1 : 0}"  
  metadata {
    annotations = {
      name = "${var.ghost_namespace}${var.counterenv}"
    }
    labels = {
      mylabel = "DEV-Ghost-Namespace${var.counterenv}"
    }
    name = "${var.ghost_namespace}${var.counterenv}"
  }
}

# Set resource quota in Namespace
#resource "kubernetes_resource_quota" "ghost_ns_quota" {
#  metadata {
#    name = "ghostdev-quota"
#    namespace="${var.ghost_namespace}${var.counterenv}"
#  }
#  spec {
#    hard = {
#      "requests.cpu" = var.ns_cpu_cores_request
#      "requests.memory" = var.ns_memory_request
#      "limits.cpu" = var.ns_cpu_cores_limit
#      "limits.memory" = var.ns_memory_limit
#    }
#  }
#  depends_on = [kubernetes_namespace.ghost_ns]
#}

# Create Storage class
resource "kubernetes_storage_class" "ghost_sc" {
    count = "${var.target_sc_add ? 1 : 0}"
    metadata {
        name =  var.storage_class
        labels =  { 
            "addonmanager.kubernetes.io/mode" = "EnsureExists"
            "kubernetes.io/cluster-service" = "true"
        } 
    }

    storage_provisioner = "disk.csi.azure.com"
    reclaim_policy      = "Delete"
    volume_binding_mode ="Immediate"
    allow_volume_expansion ="true"
    parameters = {
        "skuname" = "StandardSSD_LRS"
        "location" = var.sc_location
        "fsType" = "ext4"
        "kind"= "Managed"
    }
 }   

# create a secret for MySQL Database
resource "kubernetes_secret" "mysql_secret" {
  metadata {
    name = "db-basic-auth"
    namespace = "${var.ghost_namespace}${var.counterenv}"
  }

  data = {
    username = "${var.adminuser}"
    password = "${var.adminpassword}"
  }

  type = "kubernetes.io/basic-auth"
  depends_on = [kubernetes_namespace.ghost_ns]
}

 # Create a Persistent Volume Claim (VPC) for Database
 resource "kubernetes_persistent_volume_claim" "db_pvc" {
  metadata {
    name = var.db_pvc
    namespace = "${var.ghost_namespace}${var.counterenv}"
  }
  spec {
    storage_class_name = var.storage_class
    access_modes = [
      "ReadWriteOnce"
    ]
    resources {
      requests = {
        storage = var.db_pvc_size
      }
   }
  }
 depends_on = [kubernetes_namespace.ghost_ns,kubernetes_storage_class.ghost_sc]
}

 # Create a Persistent Volume Claim (VPC)
 resource "kubernetes_persistent_volume_claim" "ghost_pvc" {
  metadata {
    name = var.ghost_pvc
    namespace = "${var.ghost_namespace}${var.counterenv}"
  }
  spec {
    storage_class_name = var.storage_class
    access_modes = [
      "ReadWriteOnce"
    ]
    resources {
      requests = {
        storage = var.ghost_pvc_size
      }
   }
  }
 depends_on = [kubernetes_namespace.ghost_ns,kubernetes_storage_class.ghost_sc]
}

# Create MySQL Deployment

resource "kubernetes_deployment" "db_deployment" {
  metadata {
    name = "${var.db_dep_name}${var.counterenv}"
    namespace = "${var.ghost_namespace}${var.counterenv}"
    labels = local.labelsdb
  }

  spec {
    strategy {
      type="Recreate"
    }
  
    selector {
      match_labels = local.selectorsdb
    }

    template {
      metadata {
        name = var.db_cont_name
        labels = local.labelsdb
      }
      spec {
      container {
          name = var.db_cont_name
          image = "${var.db_image_url}:${var.db_image_tag}"
          image_pull_policy="IfNotPresent"
          port {
            container_port = var.db_port
          }
          volume_mount {
            mount_path = "/var/lib/mysql"
            name = "db-data"
          }
          env {
            name="MYSQL_ROOT_PASSWORD"
            value_from {
              secret_key_ref {
                name="db-basic-auth"
                key="password"
              }
            }
          }
          env {
            name="MYSQL_ROOT_HOST"
            value = "%"
          }
       }  
    
       volume {
          name = "db-data"
          persistent_volume_claim {
            claim_name = var.db_pvc
          }
        }
        } 
    }    
  } 
  depends_on = [kubernetes_namespace.ghost_ns,kubernetes_persistent_volume_claim.ghost_pvc]
}   

# Create a service for DB
resource "kubernetes_service" "db_svc1" {
  metadata {
    name = "${var.db_cont_name}-service"
    namespace = "${var.ghost_namespace}${var.counterenv}"
  }
  spec {
    port {
      port = var.db_port
      target_port = var.db_port
    }
    selector = local.selectorsdb
    type = "ClusterIP"
  }
  depends_on = [kubernetes_namespace.ghost_ns]
}

# Create a local variable for the cluster ip.
locals {
  cluster_ip = kubernetes_service.db_svc1.spec.0.cluster_ip

   depends_on = [kubernetes_service.db_svc1]
}

# create a config map for Ghost
resource "kubernetes_config_map" "ghost_config" {
  metadata {
    name = "ghost-config"
    namespace= "${var.ghost_namespace}${var.counterenv}"
  }

  data = {
    #database__connection__user="${var.adminuser}"
 #   database__connection__password="${var.adminpassword}"
    database__client="mysql"
    database__connection__host="${local.cluster_ip}"
    database__connection__database="${var.db}"
  #  database__connection__ssl__ca=data.local_file.input.content
    url="https://${var.url_host}${var.counterenv}${var.url_site}"
 }
  depends_on = [kubernetes_namespace.ghost_ns,kubernetes_deployment.db_deployment,kubernetes_service.db_svc1]
}

# Create ghost Deployment

resource "kubernetes_deployment" "ghost_deployment" {
  metadata {
    name = var.dep_name
    namespace = "${var.ghost_namespace}${var.counterenv}"
    labels = local.labels
  }

  spec {
    replicas = 1 
    selector {
      match_labels = local.selectors
    }

    template {
      metadata {
        name = var.ghost_cont_name
        labels = local.labels
      }
      spec {
      container {
          name = var.ghost_cont_name
          image = "${var.ghost_image_url}:${var.ghost_image_tag}"
          image_pull_policy="IfNotPresent"
          port {
            container_port = var.ghost_port
          }
          volume_mount {
            mount_path = "/var/lib/ghost/content"
            name = "ghost-data"
          }
          env {
            name="database__connection__user"
            value_from {
              secret_key_ref {
                name="db-basic-auth"
                key="username"
              }
            }
          }
           env {
            name="database__connection__password"
            value_from {
              secret_key_ref {
                name="db-basic-auth"
                key="password"
              }
            }
          }
          env_from {
            config_map_ref {
               name ="ghost-config"
             }
          } 
          
       }  
    
       volume {
          name = "ghost-data"
          persistent_volume_claim {
            claim_name = var.ghost_pvc
          }
        }
        } 
    }    
  } 
  depends_on = [kubernetes_namespace.ghost_ns,kubernetes_persistent_volume_claim.ghost_pvc,kubernetes_deployment.db_deployment]
}   

# Create a service for Ghost
resource "kubernetes_service" "ghost_svc1" {
  metadata {
    name = "${var.ghost_cont_name}-service"
    namespace = "${var.ghost_namespace}${var.counterenv}"
  }
  spec {
    port {
      port = 80
      target_port = var.ghost_port
    }
    selector = local.selectors
    type = "ClusterIP"
  }
  depends_on = [
    kubernetes_namespace.ghost_ns
  ]
}

# Create a namespaced X.509 certificate in your Ghost namespace 
resource "null_resource" "ingress_certif" {
  provisioner "local-exec" {
      command    = <<EOT
cat <<EOF | kubectl -n ${var.ghost_namespace}${var.counterenv} apply -f -
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: ${var.certif_name}
spec:
  secretName: ${var.secret_name}
  isCA: true
  commonName: '*.${var.domaine_name}'
  dnsNames:
    - ${var.domaine_name}
    - '*.${var.domaine_name}'
  issuerRef:
    name: ${var.ca_name} 
    kind: ClusterIssuer
EOF
EOT
  }
   depends_on = [kubernetes_namespace.ghost_ns,kubernetes_deployment.ghost_deployment]
 } 

 # Create ingress entry points for Ghost site
resource "null_resource" "ingress_entry" {
  provisioner "local-exec" {
      command    = <<EOT
cat <<EOF | kubectl -n ${var.ghost_namespace}${var.counterenv} apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
 name: ${var.url_host}${var.counterenv}${var.url_site}
 annotations:
  nginx.ingress.kubernetes.io/proxy-body-size: 64m
spec:
 ingressClassName: nginx
 rules:
   - host: ${var.url_host}${var.counterenv}${var.url_site}
     http:
      paths:
       - pathType: Prefix
         backend:
           service:
             name: ${var.ghost_cont_name}-service
             port:
              number: 80 
         path: /
 tls:
   - hosts:
     - ${var.url_host}${var.counterenv}${var.url_site}
     secretName: ${var.secret_name}
EOF
EOT
  }
   depends_on = [kubernetes_namespace.ghost_ns,null_resource.ingress_certif,kubernetes_service.ghost_svc1,kubernetes_deployment.ghost_deployment]

 } 
