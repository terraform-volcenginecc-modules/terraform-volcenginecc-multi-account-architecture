output "permission_set_id" {
  description = "权限集 ID，用于 assignment 引用"
  value       = volcenginecc_cloudidentity_permission_set.this.permission_set_id
}

output "name" {
  description = "权限集名称"
  value       = volcenginecc_cloudidentity_permission_set.this.name
}

output "id" {
  description = "Terraform 资源 ID"
  value       = volcenginecc_cloudidentity_permission_set.this.id
}
