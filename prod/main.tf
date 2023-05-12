locals {
  labels = merge(var.labels, {
    app = "ghost1"
    deploymentName = var.dep_name
  })

  selectors = merge(var.selectors, {
    app = "ghost1"
    deploymentName = var.dep_name
  })
}

data "local_file" "input" {
  filename = var.input_file
}

# Create Ghost Namespace
resource "kubernetes_namespace" "ghost_ns" {
  count ="${var.target_ns_add ? 1 : 0}"  
  metadata {
    annotations = {
      name = var.ghost_namespace
    }
    labels = {
      mylabel = "Ghost-Namespace"
    }
    name = var.ghost_namespace
  }
}

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

# create a config map
resource "kubernetes_config_map" "ghost_config" {
  metadata {
    name = "ghost-config"
    namespace= var.ghost_namespace
  }

  data = {
    database__connection__user="${var.adminuser}"
    database__connection__password="${var.adminpassword}"
    database__client="mysql"
    database__connection__host="${var.hostdb}"
    database__connection__database="${var.db}"
    database__connection__ssl__ca=data.local_file.input.content
    url="https://${var.url_site}"
 }
  depends_on = [kubernetes_namespace.ghost_ns]
}

 # Create a Persistent Volume Claim (VPC)
 resource "kubernetes_persistent_volume_claim" "ghost_pvc" {
  metadata {
    name = var.ghost_pvc
    namespace = var.ghost_namespace
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

# Create ghost Deployment

resource "kubernetes_deployment" "ghost_deployment" {
  metadata {
    name = var.dep_name
    namespace = var.ghost_namespace
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
          env_from {
            config_map_ref {
               name ="ghost-config"
             }
          } 
          resources {
            limits = {
              cpu    = var.ghost_cpu_cores
              memory = var.ghost_memory
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
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
  depends_on = [kubernetes_namespace.ghost_ns,kubernetes_persistent_volume_claim.ghost_pvc]
}   

# Create a service for Ghost
resource "kubernetes_service" "ghost_svc1" {
  metadata {
    name = "${var.ghost_cont_name}-service"
    namespace = var.ghost_namespace
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
cat <<EOF | kubectl -n ${var.ghost_namespace} apply -f -
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
cat <<EOF | kubectl -n ${var.ghost_namespace} apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
 name: ${var.url_site}
 annotations:
  nginx.ingress.kubernetes.io/proxy-body-size: 64m
spec:
 ingressClassName: nginx
 rules:
   - host: ${var.url_site}
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
     - ${var.url_site}
     secretName: ${var.secret_name}
EOF
EOT
  }
   depends_on = [kubernetes_namespace.ghost_ns,null_resource.ingress_certif,kubernetes_service.ghost_svc1,kubernetes_deployment.ghost_deployment]

 } 
