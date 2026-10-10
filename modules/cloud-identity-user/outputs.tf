output "user_id" {
  description = "云身份中心用户 ID，用于授权 principal_id"
  value       = volcenginecc_cloudidentity_user.this.user_id
}

output "user_name" {
  description = "用户名"
  value       = volcenginecc_cloudidentity_user.this.user_name
}

output "id" {
  description = "Terraform 资源 ID"
  value       = volcenginecc_cloudidentity_user.this.id
}
