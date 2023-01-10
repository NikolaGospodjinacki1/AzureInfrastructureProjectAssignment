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

variable "subnet_ranges" {
  type = list(string)
  default = ["10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24",
  "10.0.4.0/24"]
}

variable "spn-client-id" {}

variable "spn-client-secret" {}

variable "spn-tenant-id" {}