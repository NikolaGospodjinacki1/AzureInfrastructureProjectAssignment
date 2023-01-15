variable "name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "capacity" {
  type = number
}

variable "family" {
  type = string
}

variable "sku_name" {
  type = string
}

variable "environment" {
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
