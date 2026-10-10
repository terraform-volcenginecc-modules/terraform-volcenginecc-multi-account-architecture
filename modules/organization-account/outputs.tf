output "account_id" {
  description = "火山引擎账号 ID，作为后续访问授权的 target_id"
  value       = volcenginecc_organization_account.this.account_id
}

output "member_account_id" {
  description = "组织成员账号 ID"
  value       = volcenginecc_organization_account.this.member_account_id
}

output "iam_role" {
  description = "账号默认 IAM Role 名称"
  value       = volcenginecc_organization_account.this.iam_role
}

output "id" {
  description = "Terraform 资源 ID"
  value       = volcenginecc_organization_account.this.id
}
