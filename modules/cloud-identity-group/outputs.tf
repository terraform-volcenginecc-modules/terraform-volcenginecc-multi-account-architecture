output "group_id" {
  description = "用户组 ID，作为授权 principal_id（principal_type=Group）"
  value       = volcenginecc_cloudidentity_group.this.group_id
}

output "group_name" {
  description = "用户组名称"
  value       = volcenginecc_cloudidentity_group.this.group_name
}

output "id" {
  description = "Terraform 资源 ID"
  value       = volcenginecc_cloudidentity_group.this.id
}
