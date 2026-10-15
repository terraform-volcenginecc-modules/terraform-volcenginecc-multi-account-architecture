output "user_ids" {
  description = "User IDs by logical key"
  value       = { for key, user in volcenginecc_cloudidentity_user.this : key => user.user_id }
}

output "group_ids" {
  description = "Group IDs by logical key"
  value       = { for key, group in volcenginecc_cloudidentity_group.this : key => group.group_id }
}

output "principal_ids" {
  description = "User and group IDs indexed by User:key or Group:key"
  value = merge(
    { for key, user in volcenginecc_cloudidentity_user.this : "User:${key}" => user.user_id },
    { for key, group in volcenginecc_cloudidentity_group.this : "Group:${key}" => group.group_id }
  )
}
