variable "region" {
  type    = string
  default = "West Europe"
}

variable "env" {
  type    = string
  default = "dev"
}

variable "max_db_size" {
  type    = number
  default = 2
}

variable "db_sku" {
  type    = string
  default = "Basic"
}

variable "vnet_range" {
  type    = string
  default = "10.0.0.0/16"
}

variable "subnets" {
  type = map(any)
}

variable "private_dns_zones" {
  type = map(any)
}

/* variable "spn-client-id" {}

variable "spn-client-secret" {}

variable "spn-tenant-id" {} */
