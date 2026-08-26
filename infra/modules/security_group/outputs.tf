output "security_group_id" {
  description = "ID du security group créé"
  value       = aws_security_group.this.id
}

output "network_acl_id" {
  description = "ID de la Network ACL créée (bonus)"
  value       = aws_network_acl.this.id
}
