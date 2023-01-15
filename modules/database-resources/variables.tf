variable "server_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "administrator_login" {
  type = string
}

variable "administrator_login_password" {
  type      = string
  sensitive = true
}

variable "vnet_rule_name" {
  type = string
}

variable "vnet_rule_subnet_id" {
  type = string
}

variable "db_name" {
  type = string
}

variable "max_size_gb" {
  type = number
}

variable "sku_name" {
  type = string
}

variable "endpoint_name" {
  type = string
}

variable "endpoint_subnet_id" {
  type = string
}

variable "priv_svc_connection_name" {
  type = string
}

variable "private_dns_zone_name" {
  type = string
}

variable "private_dns_zone_ids" {
  type = list(string)
}

variable "environment" {
  type = string
}