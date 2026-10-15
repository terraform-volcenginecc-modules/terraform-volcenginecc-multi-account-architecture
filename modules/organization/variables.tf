variable "root_parent_id" {
  type        = string
  description = "企业组织根 OU ID"

  validation {
    condition     = trimspace(var.root_parent_id) != "" && !can(regex("替换|replace|<|>", var.root_parent_id))
    error_message = "请提供真实的企业组织根 OU ID"
  }
}

variable "organization_units" {
  type = list(object({
    key           = string
    name          = string
    description   = optional(string, "")
    parent_ou_key = optional(string, "")
  }))
  description = "固定组织单元拓扑：ou_core、ou_workloads 挂根节点，ou_production 挂 ou_workloads"
  default     = []

  validation {
    condition = length(var.organization_units) == 0 || (
      length(var.organization_units) == 3 &&
      length(distinct([for ou in var.organization_units : ou.key])) == 3 &&
      alltrue([for ou in var.organization_units :
        contains(["ou_core", "ou_workloads", "ou_production"], ou.key) &&
        ou.parent_ou_key == (ou.key == "ou_production" ? "ou_workloads" : "")
      ])
    )
    error_message = "组织单元须使用固定三层级键：ou_core、ou_workloads 挂根节点，ou_production 挂 ou_workloads"
  }
}

variable "organization_accounts" {
  type = list(object({
    account_name             = string
    show_name                = optional(string, "")
    description              = optional(string, "")
    org_unit_key             = optional(string, "")
    allow_console            = optional(number, 1)
    verification_relation_id = optional(string, "")
    account_type             = optional(string, "workload")
    tags = optional(list(object({
      key   = string
      value = string
    })), [])
  }))
  description = "要创建的成员账号列表"
  default     = []

  validation {
    condition = length(distinct([for account in var.organization_accounts : account.account_name])) == length(var.organization_accounts) && alltrue([
      for account in var.organization_accounts :
      contains([1, 2], account.allow_console) &&
      trimspace(account.account_name) != "" &&
      length(account.account_name) >= 5 && length(account.account_name) <= 20
    ])
    error_message = "account_name 必须为 5–20 个字符且唯一，allow_console 必须为 1/2"
  }
}

variable "existing_account_names" {
  type        = set(string)
  description = "已有账号名称，用于阻断新建账号与已有账号同名"
  default     = []
}

variable "common_tags" {
  type        = list(object({ key = string, value = string }))
  description = "Root project and environment tags"
  default     = []
}
