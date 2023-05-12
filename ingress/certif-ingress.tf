#   Install Certificate Manager

locals {
  certifnameissuer = var.certif_ClusterIssuer

}


resource "null_resource" "certif_ns_install" {

  # Install  Certificate Manager
  provisioner "local-exec" {
    command = "kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.11.0/cert-manager.yaml"
   
   }
  # Waiting for the pods to be ready 
  provisioner "local-exec" {
    command ="while [[ $(kubectl get pods -l app.kubernetes.io/instance=cert-manager -n ${var.certif_namespace} -o 'jsonpath={..status.conditions[?(@.type==\"Ready\")].status}') != \"True True True\" ]]; do echo \"waiting for pod\" && sleep 1; done;sleep ${var.certif_wait}"
   } 
 # Delete 
 provisioner "local-exec" {
    when    = destroy
    command = "kubectl delete -f https://github.com/cert-manager/cert-manager/releases/download/v1.11.0/cert-manager.yaml"
   
 }  
}   

# Create a certificate ClusterIssuer

resource "null_resource" "cluster_certif" {
  triggers= {
    certifnameissuer = local.certifnameissuer
  }
  depends_on = [null_resource.certif_ns_install]

  provisioner "local-exec" {
      command    = "${path.module}/scripts/ClusterIssuer.sh ${var.certif_ClusterIssuer}"
  }

  # Delete 
 provisioner "local-exec" {
    when    = destroy
    command = "${path.module}/scripts/delete_cert_clusterissuer.sh"
    environment = {
       certifnameissuer = self.triggers.certifnameissuer
    }
   
 }  
} 

# Install Ingress nginx controller 


resource "null_resource" "ingress_install" {
  
   depends_on = [null_resource.cluster_certif]

  # Install  Certificate Manager
  provisioner "local-exec" {
    command = "kubectl apply -f  https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.7.1/deploy/static/provider/cloud/deploy.yaml;sleep 60"
   
   }
 
 # Delete 
 provisioner "local-exec" {
    when    = destroy
    command = "kubectl delete -f  https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.7.1/deploy/static/provider/cloud/deploy.yaml"
   
 }  
}   

#Get Ingress Load Balancer IP
data "external" "ingress_ldb" {
  program = ["bash","${path.module}/scripts/getlbip.sh"]

  depends_on = [null_resource.ingress_install]

}