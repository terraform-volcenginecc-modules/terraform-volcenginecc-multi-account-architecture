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
    description   = optional(string, "")
    parent_ou_key = optional(string, "")
  }))
  description = "组织单元：ou_core、ou_workloads 挂根节点，ou_production 挂 ou_workloads"
  default     = []

  validation {
    condition = length(distinct([for ou in var.organization_units : ou.key])) == length(var.organization_units) && alltrue([
      for ou in var.organization_units :
      contains(["ou_core", "ou_workloads", "ou_production"], ou.key) &&
      trimspace(ou.name) != "" &&
      (ou.key == "ou_production" ? ou.parent_ou_key == "ou_workloads" : ou.parent_ou_key == "")
      ]) && alltrue([
      for ou in var.organization_units :
      ou.key != "ou_production" || contains([for parent in var.organization_units : parent.key], "ou_workloads")
    ])
    error_message = "OU key 必须唯一；Core、Workloads 挂根节点，Production 必须挂 Workloads，名称不能为空"
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
  description = "创建的成员账号列表"
  default     = []

  validation {
    condition = length(distinct([for account in var.organization_accounts : account.account_name])) == length(var.organization_accounts) && alltrue([
      for account in var.organization_accounts :
      trimspace(account.account_name) != "" &&
      length(account.account_name) >= 5 && length(account.account_name) <= 20 &&
      contains([1, 2], account.allow_console)
    ])
    error_message = "account_name 必须为 5–20 个字符且唯一，allow_console 必须为 1 或 2"
  }
}

variable "existing_organization_account_ids" {
  type        = map(string)
  description = "已有成员账号 ID 映射；key 为 account_name，仅用于权限授权，不管理账号、OU、标签或生命周期"
  default     = {}

  validation {
    condition = (
      length(distinct(values(var.existing_organization_account_ids))) == length(var.existing_organization_account_ids) &&
      alltrue([
        for account_name, account_id in var.existing_organization_account_ids :
        trimspace(account_name) != "" &&
        length(account_name) >= 5 &&
        length(account_name) <= 20 &&
        !strcontains(account_name, "|") &&
        can(regex("^[0-9]+$", account_id))
      ])
    )
    error_message = "已有账号名称必须为 5–20 个字符且不能包含 |；账号 ID 必须为唯一的数字字符串"
  }
}

variable "cloud_identity_users" {
  type = list(object({
    key                     = string
    user_name               = string
    display_name            = optional(string, "")
    description             = optional(string, "")
    email                   = optional(string, "")
    phone                   = optional(string, "")
    password_reset_required = optional(bool, true)
  }))
  description = "云身份中心用户"
  default     = []

  validation {
    condition = length(distinct([for user in var.cloud_identity_users : user.key])) == length(var.cloud_identity_users) && alltrue([
      for user in var.cloud_identity_users : trimspace(user.key) != "" && trimspace(user.user_name) != "" && !strcontains(user.key, "|")
    ])
    error_message = "用户 key 必须非空且唯一，不能包含 |；user_name 不能为空"
  }
}

variable "cloud_identity_user_passwords" {
  type        = map(string)
  description = "用户初始密码映射，key 对应 cloud_identity_users.key"
  default     = {}
  sensitive   = true

  validation {
    condition = alltrue([
      for password in values(var.cloud_identity_user_passwords) :
      length(password) >= 8 && length(password) <= 32 &&
      length(compact([
        can(regex("[A-Z]", password)) ? "upper" : "",
        can(regex("[a-z]", password)) ? "lower" : "",
        can(regex("[0-9]", password)) ? "number" : "",
        can(regex("[^A-Za-z0-9[:space:]]", password)) ? "special" : "",
      ])) >= 3
    ])
    error_message = "用户密码必须为 8 到 32 位，并包含大写、小写、数字、特殊字符中的至少三类"
  }
}

variable "cloud_identity_groups" {
  type = list(object({
    key          = string
    group_name   = string
    display_name = optional(string, "")
    description  = optional(string, "")
    join_type    = optional(string, "Manual")
    member_keys  = optional(list(string), [])
  }))
  description = "云身份中心用户组及用户成员"
  default     = []

  validation {
    condition = length(distinct([for group in var.cloud_identity_groups : group.key])) == length(var.cloud_identity_groups) && alltrue([
      for group in var.cloud_identity_groups :
      trimspace(group.key) != "" && !strcontains(group.key, "|") && trimspace(group.group_name) != "" &&
      group.join_type == "Manual" && length(distinct(group.member_keys)) == length(group.member_keys)
    ])
    error_message = "用户组 key 必须非空且唯一，不能包含 |；group_name 不能为空，join_type 必须为 Manual，成员 key 不得重复"
  }
}

variable "permission_sets" {
  type = list(object({
    key              = string
    name             = string
    description      = optional(string, "")
    session_duration = optional(number, 3600)
    relay_state      = optional(string, "")
    permission_policies = list(object({
      permission_policy_name     = optional(string, "")
      permission_policy_type     = string
      permission_policy_document = optional(string, "")
    }))
  }))
  description = "云身份中心权限集及策略"
  default     = []

  validation {
    condition = length(distinct([for permission_set in var.permission_sets : permission_set.key])) == length(var.permission_sets) && alltrue([
      for permission_set in var.permission_sets :
      trimspace(permission_set.key) != "" && !strcontains(permission_set.key, "|") && trimspace(permission_set.name) != "" &&
      permission_set.session_duration >= 3600 && permission_set.session_duration <= 43200 &&
      permission_set.session_duration == floor(permission_set.session_duration)
    ])
    error_message = "权限集 key 必须非空且唯一，不能包含 |；name 不能为空，session_duration 必须为 3600 到 43200 的整数"
  }

  validation {
    condition     = length(distinct([for permission_set in var.permission_sets : permission_set.name])) == length(var.permission_sets)
    error_message = "permission_sets.name 必须唯一，不同 key 也不能使用相同的权限集名称"
  }

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
  }))
  description = "权限集访问授权；主体引用本模板创建的用户或用户组，目标账号可为新建账号或 existing_organization_account_ids"
  default     = []

  validation {
    condition = alltrue([
      for assignment in var.permission_set_assignments :
      contains(["User", "Group"], assignment.principal_type) &&
      trimspace(assignment.permission_set_key) != "" && trimspace(assignment.principal_key) != "" &&
      trimspace(assignment.target_account_key) != ""
      ]) && length(distinct([
        for assignment in var.permission_set_assignments :
        "${assignment.permission_set_key}|${assignment.principal_type}|${assignment.principal_key}|${assignment.target_account_key}"
    ])) == length(var.permission_set_assignments)
    error_message = "授权必须填写权限集、主体、目标账号；principal_type 必须为 User/Group，且三元组不得重复"
  }
}
