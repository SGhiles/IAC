variable "resource_group_name" {
  type    = string
  default = "rg-ghiles-dev"
}

variable "location" {
  type    = string
  default = "francecentral"
}

variable "username" {
  type    = string
  default = "ghiles"
}

variable "admin_ssh_public_key" {
  description = "Cle publique SSH pour se connecter a la VM"
  type        = string
}

variable "ssh_allowed_cidr" {
  description = "IP autorisee en SSH, format CIDR"
  type        = string
}
