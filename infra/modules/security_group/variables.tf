variable "username" {
  description = "Nom du développeur, utilisé pour préfixer les noms de ressources (nomenclature du cours)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]+$", var.username))
    error_message = "username doit être en minuscules alphanumériques uniquement."
  }
}

variable "environment" {
  description = "Environnement de déploiement (dev|staging|prod)"
  type        = string

  # 1) Validation de FORMAT : uniquement des minuscules
  validation {
    condition     = can(regex("^[a-z]+$", var.environment))
    error_message = "environment doit être en minuscules uniquement."
  }

  # 2) Validation de VALEUR : uniquement une des 3 valeurs autorisées
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment doit être dev, staging ou prod."
  }
}

variable "vpc_id" {
  description = "ID du VPC dans lequel créer le security group et la Network ACL"
  type        = string
}

variable "subnet_id" {
  description = "ID du subnet à associer à la Network ACL (bonus - niveau subnet)"
  type        = string
  default     = null
}

variable "ssh_allowed_cidrs" {
  description = "Liste d'adresses IP autorisées en SSH, au format CIDR /32 (ex: [\"203.0.113.42/32\"]). Defense in depth : on peut déclarer plusieurs sources de confiance (poste + VPN), mais jamais 0.0.0.0/0."
  type        = list(string)

  validation {
    condition     = length(var.ssh_allowed_cidrs) > 0
    error_message = "ssh_allowed_cidrs ne doit pas être vide - au moins une IP doit être autorisée en SSH."
  }

  validation {
    # alltrue([for ...]) : version "vectorisée" de can(cidrhost(...)),
    # on vérifie que CHAQUE entrée de la liste est un CIDR valide.
    condition     = alltrue([for cidr in var.ssh_allowed_cidrs : can(cidrhost(cidr, 0))])
    error_message = "Chaque entrée de ssh_allowed_cidrs doit être un CIDR valide, ex: 203.0.113.42/32."
  }
}

variable "restrict_egress" {
  description = "Si true, limite le trafic sortant à HTTPS/HTTP/DNS au lieu d'un allow-all (-1). Va plus loin que le strict minimum demandé par l'énoncé sur le fail-safe default."
  type        = bool
  default     = false
}
