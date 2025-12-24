resource "azurerm_resource_group" "rg" {
  location = "East US"
  name     = "rg-deployment"
}

resource "azurerm_container_registry" "acr" {
  # FIX: Removed quotes so Terraform reads the actual location value
  location            = azurerm_resource_group.rg.location

  name                = "acrdeployment${random_string.suffix.result}"

  # FIX: Removed quotes so Terraform links to the actual Resource Group
  resource_group_name = azurerm_resource_group.rg.name

  sku                 = "Basic"
  admin_enabled       = true
}

resource "azurerm_container_app_environment" "env" {
  # FIX: Removed quotes here as well
  location            = azurerm_resource_group.rg.location

  name                = "env-deployment"

  # FIX: Removed quotes here as well
  resource_group_name = azurerm_resource_group.rg.name
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# OUTPUTS
output "acr_name" {
  value = azurerm_container_registry.acr.name
}

output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "container_app_environment_name" {
  value = azurerm_container_app_environment.env.name
}