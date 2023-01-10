terraform {
  backend "azurerm" {
    storage_account_name = "stdevtfstate12"
    container_name = "tf-state-container"
    key = "tf-project-${var.env}.tfstate"
  }
}