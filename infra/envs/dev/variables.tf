variable "aws_region" {
  description = "Région AWS où déployer"
  type        = string
  default     = "eu-west-3"
}

variable "username" {
  description = "Nom du développeur (préfixe des ressources)"
  type        = string
}

variable "environment" {
  description = "Environnement (dev|staging|prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID du VPC cible"
  type        = string
}

variable "subnet_id" {
  description = "ID du subnet pour la Network ACL (bonus)"
  type        = string
  default     = null
}

variable "ssh_allowed_cidrs" {
  description = "Liste d'IP autorisées en SSH, format CIDR /32 (au moins une)"
  type        = list(string)
}

variable "restrict_egress" {
  description = "Si true, restreint le sortant à HTTPS/HTTP/DNS au lieu d'un allow-all"
  type        = bool
  default     = false
}
