
variable "subnet_id" {
  description = "ID du subnet ou deployer l'instance"
  type        = string
}

variable "security_group_id" {
  description = "ID du security group a attacher a l'instance"
  type        = string
}

variable "instance_type" {
  description = "Type d'instance EC2"
  type        = string
  default     = "t2.micro"
}

variable "username" {
  description = "Nom du developpeur (prefixe des ressources)"
  type        = string
}

variable "environment" {
  description = "Environnement (dev|staging|prod)"
  type        = string
}
