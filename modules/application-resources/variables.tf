variable "asp_name" {
   type = string
}

variable "resource_group" {
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

variable "app_subnet" {
   type = string
}

variable "managed_id_role" {
   type = string
   default = "Contributor"
}

variable "environment" {
   type = string
}
