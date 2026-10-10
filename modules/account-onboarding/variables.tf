# ==============================================================================
# account-onboarding 模块变量
# ==============================================================================

variable "mode" {
  type        = string
  description = "账号纳管模式：create=新建成员账号；existing=纳管已有账号（需先在控制台邀请加入企业组织）"

  validation {
    condition     = contains(["create", "existing"], var.mode)
    error_message = "mode 必须是 create 或 existing"
  }
}

variable "account_name" {
  type        = string
  description = "账号名（5-20 字符，企业组织内唯一）。existing 模式下作为逻辑标识"
}

variable "show_name" {
  type        = string
  description = "账号显示名"
  default     = ""
}

variable "description" {
  type        = string
  description = "账号描述"
  default     = ""
}

variable "org_unit_id" {
  type        = string
  description = "所属组织单元 ID（create 模式必填；existing 模式仅作记录）"
  default     = ""
}

variable "allow_console" {
  type        = number
  description = "是否允许控制台登录：1 允许 / 2 不允许（仅 create 模式生效）"
  default     = 1
}

variable "verification_relation_id" {
  type        = string
  description = "继承的认证主体 ID。单主体场景留空（仅 create 模式生效）"
  default     = ""
}

variable "account_type" {
  type        = string
  description = "账号类型：operation / security / logging / production / staging / workload / sandbox"
  default     = "workload"

  validation {
    condition = contains(
      ["operation", "security", "logging", "production", "staging", "workload", "sandbox"],
      var.account_type
    )
    error_message = "account_type 必须是 operation / security / logging / production / staging / workload / sandbox 之一"
  }
}

variable "existing_account_id" {
  type        = string
  description = "existing 模式下，已有火山引擎账号 ID"
  default     = ""
}

variable "financial_relation_verified" {
  type        = bool
  description = "财务托管关系是否已在控制台手动完成（true 表示已完成）。create/existing 模式均需校验"
  default     = false
}

variable "skip_financial_relation_gate" {
  type        = bool
  description = "是否跳过财务托管关系校验门禁（仅测试环境使用，生产环境保持 false）"
  default     = false
}

variable "tags" {
  type = list(object({
    key   = string
    value = string
  }))
  description = "业务自定义标签（模块会自动叠加 AccountType 标签）"
  default     = []
}
