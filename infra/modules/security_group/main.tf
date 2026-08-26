# Nomenclature du cours : jamais de nom de ressource en dur.
# On construit un préfixe à partir des variables, et tous les noms
# en dérivent. Ça évite les collisions entre devs/environnements
# et ça rend le module réutilisable tel quel en dev, staging, prod.
locals {
  prefix = "${var.username}-${var.environment}"

  common_tags = {
    Project     = "iac-marie"
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  # Sortant "normal" : tout est ouvert (comportement demandé par
  # l'énoncé). Sortant "restreint" : uniquement HTTPS/HTTP/DNS,
  # activé via var.restrict_egress pour pousser le fail-safe default
  # plus loin que le strict minimum.
  egress_open = [
    { description = "Autorise tout le trafic sortant", protocol = "-1", from_port = 0, to_port = 0 },
  ]
  egress_restricted = [
    { description = "Sortant HTTPS", protocol = "tcp", from_port = 443, to_port = 443 },
    { description = "Sortant HTTP", protocol = "tcp", from_port = 80, to_port = 80 },
    { description = "Sortant DNS", protocol = "udp", from_port = 53, to_port = 53 },
  ]
  egress_rules = var.restrict_egress ? local.egress_restricted : local.egress_open
}

# ------------------------------------------------------------------
# GROUPE DE SECURITE (pare-feu au niveau de l'instance EC2)
#
# FAIL-SAFE DEFAULT : un security group AWS refuse tout le trafic
# entrant par défaut. On liste ici, explicitement, la SEULE chose
# qu'on autorise : HTTP pour tout le monde, SSH pour des IP précises.
# Rien d'autre ne passera, même sans règle "deny" écrite quelque part.
# ------------------------------------------------------------------

resource "aws_security_group" "this" {
  # name_prefix plutôt que name : si ce SG doit un jour être remplacé
  # (changement d'un attribut qui force le recreate), un nom fixe
  # entrerait en conflit avec l'ancien tant qu'il n'est pas détruit.
  # name_prefix + create_before_destroy évite la coupure de service.
  name_prefix = "${local.prefix}-sg-"
  description = "SG serveur web : HTTP ouvert + SSH restreint (fail-safe default)"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  # Règle entrante n°1 : HTTP, ouvert à tous.
  # checkov:skip=CKV_AWS_260: exposition HTTP publique volontaire, c'est un serveur web
  ingress {
    description = "Autorise le trafic HTTP depuis toutes les sources"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Règle entrante n°2 : SSH, une ou plusieurs IP de confiance.
  # dynamic + for_each : une règle générée par CIDR dans la liste,
  # sans dupliquer le bloc ingress à la main pour chaque IP.
  dynamic "ingress" {
    for_each = var.ssh_allowed_cidrs
    content {
      description = "Autorise le SSH depuis une IP administrateur de confiance"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  # Règle(s) sortante(s) : écrites explicitement (sinon AWS applique
  # quand même un allow-all -1 par défaut). Le contenu dépend de
  # var.restrict_egress (voir locals.egress_rules ci-dessus).
  dynamic "egress" {
    for_each = local.egress_rules
    content {
      description = egress.value.description
      protocol    = egress.value.protocol
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.prefix}-sg"
  })
}

# ------------------------------------------------------------------
# BONUS - NETWORK ACL (pare-feu au niveau du subnet)
#
# DEFENSE IN DEPTH : deuxième couche de filtrage, indépendante du
# security group, au niveau du subnet cette fois. On la garde
# volontairement plus large que le SG (allow-all en sortie, quel
# que soit var.restrict_egress) : chaque couche a un rôle différent
# - la NACL filtre grossièrement au niveau du subnet, le SG applique
# la politique fine par instance. Les dupliquer à l'identique
# n'apporterait rien de plus en sécurité, juste de la maintenance.
#
# Différence importante avec le security group : une NACL est
# STATELESS (le SG est STATEFUL). Il faut donc autoriser
# explicitement le trafic ALLER et le trafic RETOUR (ports
# éphémères), sinon les réponses aux requêtes seront bloquées.
#
# FAIL-SAFE DEFAULT : une NACL personnalisée créée par Terraform
# refuse tout par défaut (contrairement à la NACL par défaut du VPC
# qui autorise tout). On doit donc tout lister explicitement, y
# compris le trafic sortant.
# ------------------------------------------------------------------

resource "aws_network_acl" "this" {
  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_id != null ? [var.subnet_id] : []

  tags = merge(local.common_tags, {
    Name = "${local.prefix}-nacl"
  })
}

# --- Entrant ---

resource "aws_network_acl_rule" "in_http" {
  network_acl_id = aws_network_acl.this.id
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

# for_each sur la liste de CIDR SSH : une règle par IP autorisée,
# avec un rule_number distinct (110, 111, 112...). Pense-bête : ça
# suppose moins de 10 IP dans la liste pour ne pas chevaucher la
# règle des ports éphémères (120) - largement suffisant ici.
resource "aws_network_acl_rule" "in_ssh" {
  for_each = { for idx, cidr in var.ssh_allowed_cidrs : idx => cidr }

  network_acl_id = aws_network_acl.this.id
  rule_number    = 110 + tonumber(each.key)
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = each.value
  from_port      = 22
  to_port        = 22
}

# Ports éphémères (1024-65535) : nécessaires pour laisser revenir
# les réponses des connexions HTTP/SSH initiées par les clients.
resource "aws_network_acl_rule" "in_ephemeral" {
  network_acl_id = aws_network_acl.this.id
  rule_number    = 120
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

# --- Sortant ---

resource "aws_network_acl_rule" "out_all" {
  network_acl_id = aws_network_acl.this.id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}
