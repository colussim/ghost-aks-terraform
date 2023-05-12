output "az_resource_group" {
  value = var.resource_group_name
}

output "az_cluster_name" {
  value = azurerm_kubernetes_cluster.DRONE_aks_cl.name
}

output "az_cluster_endpoint" {
  value = azurerm_kubernetes_cluster.DRONE_aks_cl.fqdn
}


output "run_this_command_to_configure_kubectl" {
  value = "az aks get-credentials --name ${azurerm_kubernetes_cluster.DRONE_aks_cl.name} --resource-group ${var.resource_group_name}"
}

output "client_certificate" {
  value = azurerm_kubernetes_cluster.DRONE_aks_cl.kube_config.0.client_certificate
   sensitive = true
}

output "kube_config" {
  value = azurerm_kubernetes_cluster.DRONE_aks_cl.kube_config_raw
  sensitive = true
}

output "az_virtual_network" {
  value = azurerm_virtual_network.DRONE_aks_net.name
   
}