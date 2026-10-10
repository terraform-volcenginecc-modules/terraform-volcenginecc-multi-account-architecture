# ==============================================================================
# account-onboarding 模块输出
# ==============================================================================

output "account_id" {
  description = "火山引擎账号 ID，作为下游访问授权的 target_id"
  value       = var.mode == "create" ? module.create[0].account_id : var.existing_account_id
}

output "member_account_id" {
  description = "组织成员账号 ID（仅 create 模式有值；existing 模式返回空串）"
  value       = var.mode == "create" ? module.create[0].member_account_id : ""
}

output "iam_role" {
  description = "账号默认 IAM Role 名称（仅 create 模式有值）"
  value       = var.mode == "create" ? module.create[0].iam_role : ""
}

output "mode" {
  description = "实际纳管模式"
  value       = var.mode
}

output "account_type" {
  description = "账号类型"
  value       = var.account_type
}

output "financial_relation_verified" {
  description = "财务托管关系是否已校验通过"
  value       = var.financial_relation_verified
}
