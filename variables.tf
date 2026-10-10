variable "region" {
  type        = string
  description = "火山引擎地域"
  default     = "cn-beijing"
}

variable "project" {
  type        = string
  description = "工程标识，用于资源标签"
  default     = "cloud-identity-iac"
}

variable "environment" {
  type        = string
  description = "环境标识"
  default     = "prod"
}

variable "root_parent_id" {
  type        = string
  description = "企业组织根 OU ID"
}

variable "organization_units" {
  type = list(object({
    key           = string
    name          = string
    description   = string
    parent_ou_key = string
  }))
  description = "固定组织单元拓扑：ou_core、ou_workloads 挂根节点，ou_production 挂 ou_workloads"
  default     = []
}

variable "organization_accounts" {
  type = list(object({
    mode                        = string
    account_name                = string
    show_name                   = string
    description                 = string
    org_unit_key                = string
    allow_console               = number
    verification_relation_id    = string
    account_type                = string
    existing_account_id         = string
    financial_relation_verified = bool
    tags = list(object({
      key   = string
      value = string
    }))
  }))
  description = "成员账号列表；mode 支持 create 和 existing"
  default     = []

  validation {
    condition = alltrue([
      for account in var.organization_accounts :
      contains(["create", "existing"], account.mode) &&
      contains([1, 2], account.allow_console) &&
      (account.mode == "create" ? account.existing_account_id == "" : account.existing_account_id != "")
    ])
    error_message = "账号 mode 必须为 create/existing，allow_console 必须为 1/2，且 existing_account_id 必须与模式匹配"
  }
}

variable "skip_financial_relation_gate" {
  type        = bool
  description = "是否跳过财务关系人工确认门禁；资源栈一键部署默认跳过"
  default     = true
}

variable "cloud_identity_account_propagation_wait" {
  type        = string
  description = "新成员账号同步到云身份中心后再下发权限集的等待时间"
  default     = "180s"
}

variable "identity_source_mode" {
  type        = string
  description = "身份源模式：local、saml 或 saml_scim"
  default     = "local"

  validation {
    condition     = contains(["local", "saml", "saml_scim"], var.identity_source_mode)
    error_message = "identity_source_mode 必须是 local、saml 或 saml_scim"
  }
}

variable "identity_provider_name" {
  type        = string
  description = "SAML 身份提供商名称"
  default     = ""
}

variable "saml_configured" {
  type        = bool
  description = "SAML 是否已在云身份中心配置完成"
  default     = false
}

variable "scim_configured" {
  type        = bool
  description = "SCIM 是否已在云身份中心配置完成"
  default     = false
}

variable "skip_identity_source_gate" {
  type        = bool
  description = "是否跳过身份源人工确认门禁"
  default     = false
}

variable "cloud_identity_users" {
  type = list(object({
    key                     = string
    user_name               = string
    display_name            = string
    description             = string
    email                   = string
    phone                   = string
    password_reset_required = bool
  }))
  description = "Terraform 管理的云身份中心本地用户"
  default     = []
}

variable "cloud_identity_user_passwords" {
  type        = map(string)
  description = "本地用户初始密码映射，key 对应 cloud_identity_users.key"
  default     = {}
  sensitive   = true
}

variable "cloud_identity_groups" {
  type = list(object({
    key          = string
    group_name   = string
    display_name = string
    description  = string
    join_type    = string
    member_keys  = list(string)
  }))
  description = "Terraform 管理的 Manual 用户组"
  default     = []

  validation {
    condition     = alltrue([for group in var.cloud_identity_groups : group.join_type == "Manual"])
    error_message = "Terraform 管理的用户组必须使用 Manual；SCIM 同步组请通过 external_principals 引用"
  }
}

variable "external_principals" {
  type = map(object({
    principal_type = string
    principal_id   = string
  }))
  description = "SCIM 或外部流程维护的云身份中心用户/组"
  default     = {}

  validation {
    condition = alltrue([
      for principal in values(var.external_principals) :
      contains(["User", "Group"], principal.principal_type) && principal.principal_id != ""
    ])
    error_message = "external_principals 的 principal_type 必须为 User/Group，且 principal_id 不能为空"
  }
}

variable "permission_sets" {
  type = list(object({
    key              = string
    name             = string
    description      = string
    session_duration = number
    relay_state      = string
    permission_policies = list(object({
      permission_policy_name     = string
      permission_policy_type     = string
      permission_policy_document = string
    }))
  }))
  description = "云身份中心权限集"
  default     = []

  validation {
    condition = alltrue(flatten([
      for permission_set in var.permission_sets : [
        for policy in permission_set.permission_policies :
        contains(["System", "Inline"], policy.permission_policy_type) &&
        (
          policy.permission_policy_type == "System"
          ? policy.permission_policy_name != "" && policy.permission_policy_document == ""
          : policy.permission_policy_document != "" && can(jsondecode(policy.permission_policy_document))
        )
      ]
    ]))
    error_message = "System 策略必须提供名称且文档为空；Inline 策略必须提供合法 JSON 文档"
  }
}

variable "permission_set_assignments" {
  type = list(object({
    permission_set_key = string
    principal_type     = string
    principal_key      = string
    target_account_key = string
    target_account_id  = string
  }))
  description = "权限集访问授权；目标账号逻辑 key 与直接账号 ID 二选一"
  default     = []

  validation {
    condition = alltrue([
      for assignment in var.permission_set_assignments :
      contains(["User", "Group"], assignment.principal_type) &&
      ((assignment.target_account_key != "") != (assignment.target_account_id != ""))
    ])
    error_message = "principal_type 必须为 User/Group，且 target_account_key 与 target_account_id 必须恰好填写一个"
  }
}
