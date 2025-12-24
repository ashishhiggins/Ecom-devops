resource "azurerm_resource_group" "rg" {
  location = "East US"
  name     = "rg-deployment"
}

# --- 1. NETWORKING & REGISTRY ---
resource "azurerm_container_registry" "acr" {
  name                = "acrdeployment${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

resource "azurerm_container_app_environment" "env" {
  name                = "env-deployment"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# --- 2. IDENTITY (The "ID Badge") ---
resource "azurerm_user_assigned_identity" "app_identity" {
  name                = "ecom-api-identity"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

# --- 3. PERMISSIONS (Give Identity access to ACR) ---
resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.app_identity.principal_id
}

# --- 4. THE APP (Pre-configured with Identity) ---
resource "azurerm_container_app" "app" {
  name                         = "ecom-api-v1" # This must match your GitHub Secret
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"

  # A. Attach the Identity to the App
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.app_identity.id]
  }

  # B. Tell App to use Identity for this Registry
  registry {
    server   = azurerm_container_registry.acr.login_server
    identity = azurerm_user_assigned_identity.app_identity.id
  }

  template {
    container {
      name   = "java-app"
      # We use a placeholder image first. GitHub Actions will overwrite this later.
      image  = "mcr.microsoft.com/k8se/quickstart:latest"
      cpu    = 0.5
      memory = "1.0Gi"
    }
  }

  # C. Configure Port 8080 (So you don't have to do it manually)
  ingress {
    allow_insecure_connections = false
    external_enabled           = true
    target_port                = 8080
    traffic_weight {
      percentage = 100
      latest_revision = true
    }
  }
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# --- OUTPUTS ---
output "acr_name" {
  value = azurerm_container_registry.acr.name
}

output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "container_app_environment_name" {
  value = azurerm_container_app_environment.env.name
}

output "container_app_name" {
  value = azurerm_container_app.app.name
}

output "app_url" {
  value = azurerm_container_app.app.latest_revision_fqdn
}