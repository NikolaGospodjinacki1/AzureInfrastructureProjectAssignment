variable "asp_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "sku_name" {
  type = string
}

variable "app_name" {
  type = string
}

variable "app_subnet_id" {
  type = string
}

variable "endpoint_subnet_id" {
  type = string
}

variable "managed_id_role" {
  type    = string
  default = "Contributor"
}

variable "instrumentation_key" {
  type = string
}

variable "private_dns_zone_name" {
  type = string
}

variable "vnet_id" {
  type = string
}

variable "endpoint_name" {
  type = string
}

variable "priv_svc_connection_name" {
  type = string
}

variable "private_dns_zone_ids" {
  type = list(string)
}

variable "environment" {
  type = string
}
