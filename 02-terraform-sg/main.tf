terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
provider "aws" {
  region = "us-east-1"
}
variable "vpc_id" {
  type = string
}
variable "mon_ip" {
  type = string
}
resource "aws_security_group" "web" {
  name        = "websg-ghiles"
  description = "Securite groupe - HTTP public, SSH restreint"
  vpc_id      = var.vpc_id
  tags = {
    Name = "websg-ghiles"
  }
}
resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.web.id
  description        = "Autorise HTTP depuis internet"
  ip_protocol        = "tcp"
  from_port          = 80
  to_port            = 80
  cidr_ipv4          = "0.0.0.0/0"
}
resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.web.id
  description        = "Autorise SSH uniquement depuis mon IP"
  ip_protocol        = "tcp"
  from_port          = 22
  to_port            = 22
  cidr_ipv4          = "${var.mon_ip}/32"
}
resource "aws_vpc_security_group_egress_rule" "all_out" {
  security_group_id = aws_security_group.web.id
  description        = "Autorise tout le trafic sortant"
  ip_protocol        = "-1"
  cidr_ipv4          = "0.0.0.0/0"
}
output "security_group_id" {
  value = aws_security_group.web.id
}
resource "aws_network_acl" "web_nacl" {
  vpc_id = var.vpc_id
  tags = {
    Name = "nacl-web-ghiles"
  }
}
resource "aws_network_acl_association" "web" {
  network_acl_id = aws_network_acl.web_nacl.id
  subnet_id       = "subnet-090a9778c2c74d0e7"
}
resource "aws_network_acl_rule" "in_http" {
  network_acl_id = aws_network_acl.web_nacl.id
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}
resource "aws_network_acl_rule" "in_ssh" {
  network_acl_id = aws_network_acl.web_nacl.id
  rule_number    = 110
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "${var.mon_ip}/32"
  from_port      = 22
  to_port        = 22
}
resource "aws_network_acl_rule" "in_ephemeral" {
  network_acl_id = aws_network_acl.web_nacl.id
  rule_number    = 120
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}
resource "aws_network_acl_rule" "out_all" {
  network_acl_id = aws_network_acl.web_nacl.id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}
output "nacl_id" {
  value = aws_network_acl.web_nacl.id
}
