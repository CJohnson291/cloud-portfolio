resource "azurerm_resource_group" "portfolio" {
  name     = "cloud-portfolio-rg"
  location = "West Europe"

  tags = {
    Project     = "cloud-portfolio"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

resource "azurerm_storage_account" "portfolio" {
  name                     = "cloudportfoliostcj"
  resource_group_name      = azurerm_resource_group.portfolio.name
  location                 = azurerm_resource_group.portfolio.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    Project     = "cloud-portfolio"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

resource "azurerm_storage_table" "visitor_count" {
  name                 = "visitorcounts"
  storage_account_name = azurerm_storage_account.portfolio.name
}

resource "azurerm_service_plan" "portfolio" {
  name                = "cloud-portfolio-plan"
  resource_group_name = azurerm_resource_group.portfolio.name
  location            = azurerm_resource_group.portfolio.location
  os_type             = "Linux"
  sku_name            = "Y1"

  tags = {
    Project     = "cloud-portfolio"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

resource "azurerm_linux_function_app" "portfolio" {
  name                       = "cloud-portfolio-api-cj"
  resource_group_name        = azurerm_resource_group.portfolio.name
  location                   = azurerm_resource_group.portfolio.location
  storage_account_name       = azurerm_storage_account.portfolio.name
  storage_account_access_key = azurerm_storage_account.portfolio.primary_access_key
  service_plan_id            = azurerm_service_plan.portfolio.id

  site_config {
    application_stack {
      python_version = "3.11"
    }
    cors {
      allowed_origins = ["https://d3rqh12vcebb1z.cloudfront.net"]
    }
  }

  app_settings = {
    "STORAGE_CONNECTION_STRING" = azurerm_storage_account.portfolio.primary_connection_string
    "STORAGE_TABLE_NAME"        = azurerm_storage_table.visitor_count.name
    "FUNCTIONS_WORKER_RUNTIME"  = "python"
  }

  tags = {
    Project     = "cloud-portfolio"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}