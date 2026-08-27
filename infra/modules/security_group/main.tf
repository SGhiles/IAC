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

#trivy:ignore:AWS-0104 sortant HTTPS/HTTP/DNS vers Internet : la destination ne peut pas etre restreinte a des IP fixes sans casser le fonctionnement normal du serveur. Filtrage fait par PORT (restrict_egress).
resource "aws_security_group" "this" {
  name_prefix = "${local.prefix}-sg-"
  description = "SG serveur web : HTTP ouvert + SSH restreint (fail-safe default)"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  # checkov:skip=CKV_AWS_260: exposition HTTP publique volontaire, c'est un serveur web
  ingress {
    description = "Autorise le trafic HTTP depuis toutes les sources"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #trivy:ignore:AWS-0107 ping ouvert a tous a des fins de demonstration pedagogique du filtrage par protocole (voir compte-rendu).
  ingress {
    description = "Autorise le ping ICMP depuis toutes les sources"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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

resource "aws_network_acl" "this" {
  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_id != null ? [var.subnet_id] : []

  tags = merge(local.common_tags, {
    Name = "${local.prefix}-nacl"
  })
}

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

resource "aws_network_acl_rule" "in_icmp" {
  network_acl_id = aws_network_acl.this.id
  rule_number    = 105
  egress         = false
  protocol       = "icmp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = -1
  to_port        = -1
}

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

#trivy:ignore:AWS-0102 defense in depth : le SG applique deja la politique fine par port, cette NACL sert de filet plus large au niveau subnet.
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
