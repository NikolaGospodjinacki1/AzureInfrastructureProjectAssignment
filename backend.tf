terraform {
  backend "azurerm" {
    storage_account_name = "stterraformstate4321"
    container_name = "st-terraform-state"
    key = "tf-project-assignment.tfstate"
  }
}