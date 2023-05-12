# Create AKS Cluster 

# Virtual Network Subnet  #

resource "azurerm_virtual_network" "DRONE_aks_net" {
  name                = "${var.prefix}-network"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = ["10.1.0.0/16"]
}

resource "azurerm_subnet" "DRONE_aks_sb" {
  name                 = "${var.prefix}-subnet"
  virtual_network_name = azurerm_virtual_network.DRONE_aks_net.name
  resource_group_name  = var.resource_group_name
  address_prefixes     = ["10.1.0.0/22"]
}

# Deploy Azure Kubernetes Service  #

resource "azurerm_kubernetes_cluster" "DRONE_aks_cl" {
  name                = "${var.prefix}-aks"
  location            =  "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  dns_prefix          = "${var.prefix}-aks01"
  kubernetes_version = "${var.k8sversion}"

  default_node_pool {
    name                = "${var.prefix}pool"
    node_count          = 2
    orchestrator_version = "${var.k8sversion}"
    vm_size             = "${var.vm_type}"
    type                = "VirtualMachineScaleSets"
    zones  = ["1", "2"]
    enable_auto_scaling = true
    min_count           = 2
    max_count           = 4
    os_disk_size_gb     = 50

    vnet_subnet_id = azurerm_subnet.DRONE_aks_sb.id
  }

  identity {
    type = "SystemAssigned"
  }

  azure_policy_enabled = false

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
  }
  
  # Enable the Ingress controller for the AKS cluster.
  http_application_routing_enabled = true

  tags = {
    Environment = "${var.env}"
  }
}