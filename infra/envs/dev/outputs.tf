output "security_group_id" {
  value = module.security_group.security_group_id
}

output "network_acl_id" {
  value = module.security_group.network_acl_id
}
