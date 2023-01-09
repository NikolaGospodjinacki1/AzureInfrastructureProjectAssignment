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

variable "dns_zone_name" {
  type = string
}

variable "dns_zone_virtual_network_link_name" {
  type = string
}

variable "virtual_network_id" {
  type = string
}