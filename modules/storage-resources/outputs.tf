output "storage_account_id" {
  value = azurerm_storage_account.projectsa1.id
}

output "storage_account_key1" {
  value = azurerm_storage_account.projectsa1.primary_access_key
}

output "storage_account_key2" {
  value = azurerm_storage_account.projectsa1.secondary_access_key
}

output "storage_account_name" {
  value = azurerm_storage_account.projectsa1.name
}