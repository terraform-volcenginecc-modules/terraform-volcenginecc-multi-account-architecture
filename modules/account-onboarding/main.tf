# ==============================================================================
# 模块：account-onboarding
# 功能：企业组织成员账号纳管统一入口
# 描述：支持两种纳管模式：
#   - create：通过 organization-account 模块新建成员账号
#   - existing：纳管已有火山引擎账号（需先在控制台完成"邀请加入企业组织"）
#              模块仅记录 account_id 供下游授权使用，不重复创建
# 无论哪种模式，均会触发"财务托管关系"人工校验门禁（financial_relation_verified），
# 确保每个账号在 IaC 流水线通过前都已完成财务关系配置。
# 设计要点：
#   - 账号创建与财务关系校验解耦：账号资源先创建/记录，terraform_data 门禁后置校验
#   - existing 模式下账号不在 Terraform state 中管理，仅作为下游引用的锚点
# ==============================================================================

# ------------------------------------------------------------------------------
# Create 模式：新建成员账号
# ------------------------------------------------------------------------------
module "create" {
  count  = var.mode == "create" ? 1 : 0
  source = "../organization-account"

  account_name             = var.account_name
  show_name                = var.show_name
  description              = var.description
  org_unit_id              = var.org_unit_id
  allow_console            = var.allow_console
  verification_relation_id = var.verification_relation_id

  # 自动叠加 AccountType 标签 + 通用标签
  tags = concat(
    var.tags,
    [{ key = "AccountType", value = var.account_type }],
  )
}

# ------------------------------------------------------------------------------
# Existing 模式：记录已有账号（不创建）
# ------------------------------------------------------------------------------
# existing 模式要求：
#   1. 账号已被邀请加入企业组织（控制台手动操作，volcenginecc 无对应资源）
#   2. 提供 existing_account_id
#   3. 财务托管关系已配置（financial_relation_verified = true）
resource "terraform_data" "existing_anchor" {
  count = var.mode == "existing" ? 1 : 0

  # 用 account_name + account_id 作为稳定触发器
  triggers_replace = [var.account_name, var.existing_account_id]

  lifecycle {
    precondition {
      condition     = var.existing_account_id != ""
      error_message = "existing 模式必须提供 existing_account_id（已有火山引擎账号 ID）"
    }
  }
}

# ------------------------------------------------------------------------------
# 财务托管关系校验门禁（create 与 existing 通用）
# ------------------------------------------------------------------------------
# volcenginecc 暂不提供 financial_relation 资源，财务托管需在控制台手动完成。
# 该校验门禁在账号创建/记录之后执行，若 financial_relation_verified 为 false，
# apply 会在此处失败并提示用户完成手动配置后再置为 true。
# 可通过栈级变量 skip_financial_relation_gate 整体跳过（仅用于测试环境）。
resource "terraform_data" "financial_relation_gate" {
  triggers_replace = [var.account_name, var.account_type]

  # 确保账号资源先创建/记录，再做门禁校验
  depends_on = [
    module.create,
    terraform_data.existing_anchor,
  ]

  lifecycle {
    precondition {
      condition     = var.skip_financial_relation_gate || var.financial_relation_verified
      error_message = <<EOT
账号 "${var.account_name}"（类型：${var.account_type}）尚未完成财务托管关系配置。

操作步骤：
  1. 登录火山引擎控制台 → 企业组织 → 财务管理
  2. 为该账号配置财务托管关系（付款/出账主体等）
  3. 回到 terraform.tfvars，将该账号的 financial_relation_verified 置为 true
  4. 重新执行 terraform apply

若为测试环境，可在栈级设置 skip_financial_relation_gate = true 跳过此门禁。
EOT
    }
  }
}
