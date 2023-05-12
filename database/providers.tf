terraform {
  required_version = ">=1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

# Get AKS cluster config
data "terraform_remote_state" "aks" {
  backend = "local"
  config = {
    path = "../aks/terraform.tfstate"
  }
}

# GET AKS cluster name
#data "azurerm_kubernetes_cluster" "cluster" {
  #virtual_netname = data.terraform_remote_state.aks.outputs.az_virtual_network
  #resource_group_name = data.terraform_remote_state.aks.outputs.az_resource_group
#}


provider "azurerm" {
  features {}
  subscription_id = "65c24700-9417-4e3e-a2f5-8c24f4b2cc68"
  client_id       = "b23e63f3-392b-4972-838b-ad7b09b4a927"
  client_secret   = "w578Q~eMvn2dpTaQsgCUrb17NoEPU_Sn1Cta4auS" 
  tenant_id       = "69dd55fd-cffc-4b49-ad25-f210bf77f8f4"
}
