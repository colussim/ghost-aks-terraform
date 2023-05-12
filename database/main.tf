# Deployment of the mysql service

data "azurerm_virtual_network" "vnet_aks_se2" {
  name                 = data.terraform_remote_state.aks.outputs.az_virtual_network
  resource_group_name  = var.resource_group_name
}

# Create subnet
resource "azurerm_subnet" "se_ec_subnet" {
  name                 = "${var.subnet_name}"
  resource_group_name  = "${var.resource_group_name}"
  virtual_network_name = "${data.azurerm_virtual_network.vnet_aks_se2.name}"
  address_prefixes     = ["10.1.4.0/24"]
   delegation {
    name = "fs"
    service_delegation {
     name = "Microsoft.DBforMySQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

# Enables you to manage Private DNS zones within Azure DNS
resource "azurerm_private_dns_zone" "default" {
  name                = "${var.db_hostname}.mysql.database.azure.com"
  resource_group_name = "${var.resource_group_name}"

}
# Enables you to manage Private DNS zone Virtual Network Links
resource "azurerm_private_dns_zone_virtual_network_link" "default" {
  name                  = "mysqlfsVnetZone${var.db_hostname}.com"
  private_dns_zone_name = azurerm_private_dns_zone.default.name
  resource_group_name   = "${var.resource_group_name}"
  virtual_network_id    = "${data.azurerm_virtual_network.vnet_aks_se2.id}"
}



# Manages the MySQL Flexible Server
resource "azurerm_mysql_flexible_server" "default" {
  location                     ="${var.location}"
  name                         = "mysqlfs-${var.db_hostname}"
  resource_group_name          = "${var.resource_group_name}"
  administrator_login          = "${var.adminuser}"
  administrator_password       = "${var.adminpassword}"
  backup_retention_days        = 7
  delegated_subnet_id          = azurerm_subnet.se_ec_subnet.id
  geo_redundant_backup_enabled = false
  private_dns_zone_id          = azurerm_private_dns_zone.default.id
  sku_name                     = "${var.vm_type}"
  version                      = "8.0.21"
  #zone                         = "1"
  
  
  #sl_enforcement_enabled = true
  #infrastructure_encryption_enabled = false
  #auto_grow_enabled = true
  #public_network_access_enabled = true 


  high_availability {
   mode                      = "SameZone"
   # mode = "ZoneRedundant" 
    #standby_availability_zone = "2"
  }

  storage {
    iops    = 360
    size_gb = 20
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.default]
}

# Manages the MySQL Flexible Server Database
resource "azurerm_mysql_flexible_database" "main" {
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
  name                = "mysqlfsdb_${var.db_hostname}"
  resource_group_name = "${var.resource_group_name}"
  server_name         = azurerm_mysql_flexible_server.default.name

depends_on = [azurerm_mysql_flexible_server.default]

}

# This rule is to enable the 'Allow access to Azure services' checkbox
resource "azurerm_mysql_flexible_server_firewall_rule" "main" {
  name                = "mysqlfs-mysql-firewall"
  resource_group_name = "${var.resource_group_name}"
  server_name         = "${azurerm_mysql_flexible_server.default.name}"
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"

  depends_on = [azurerm_mysql_flexible_server.default,azurerm_mysql_flexible_database.main]
}
resource "null_resource" "wget" {
  provisioner "local-exec" {
      command    = "wget --no-check-certificate -P certificates/ https://dl.cacerts.digicert.com/DigiCertGlobalRootCA.crt.pem"
  }
   depends_on = [azurerm_mysql_flexible_server.default,azurerm_mysql_flexible_database.main,azurerm_mysql_flexible_server_firewall_rule.main]
 }  
