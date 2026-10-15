# 示例：混合部署——创建 5 个新账号，并复用 1 个已有账号做权限授权。
# 已有账号只通过 ID 引用，不管理其 OU、标签或生命周期。密码必须在部署前填写。
# 下方 root_parent_id、已有账号 ID、资源名称等均为示例占位值，部署前请替换为目标环境的实际值。
region         = "cn-beijing"
project        = "default"
environment    = "prod"
root_parent_id = "7000000000000000000"

organization_units = [
  {
    key           = "ou_core"
    name          = "Core-Example"
    description   = "运维、安全、日志等核心账号"
    parent_ou_key = ""
  },
  {
    key           = "ou_workloads"
    name          = "Workloads-Example"
    description   = "业务负载账号"
    parent_ou_key = ""
  },
  {
    key           = "ou_production"
    name          = "Production-Example"
    description   = "生产环境"
    parent_ou_key = "ou_workloads"
  },
]

organization_accounts = [
  {
    account_name             = "ci-example-ops"
    show_name                = "ci-example-ops"
    description              = "运维管理账号"
    org_unit_key             = "ou_core"
    allow_console            = 1
    verification_relation_id = ""
    account_type             = "operation"
    tags = [
      { key = "CostCenter", value = "OPS-EXAMPLE" },
    ]
  },
  {
    account_name             = "ci-example-sec"
    show_name                = "ci-example-sec"
    description              = "安全审计账号"
    org_unit_key             = "ou_core"
    allow_console            = 1
    verification_relation_id = ""
    account_type             = "security"
    tags = [
      { key = "CostCenter", value = "SEC-EXAMPLE" },
    ]
  },
  {
    account_name             = "ci-example-log"
    show_name                = "ci-example-log"
    description              = "日志归集账号"
    org_unit_key             = "ou_core"
    allow_console            = 1
    verification_relation_id = ""
    account_type             = "logging"
    tags = [
      { key = "CostCenter", value = "LOG-EXAMPLE" },
    ]
  },
  {
    account_name             = "ci-example-prod"
    show_name                = "ci-example-prod"
    description              = "生产业务账号"
    org_unit_key             = "ou_production"
    allow_console            = 1
    verification_relation_id = ""
    account_type             = "production"
    tags = [
      { key = "CostCenter", value = "PROD-EXAMPLE" },
    ]
  },
  {
    account_name             = "ci-example-stg"
    show_name                = "ci-example-stg"
    description              = "预发测试账号"
    org_unit_key             = "ou_workloads"
    allow_console            = 1
    verification_relation_id = ""
    account_type             = "staging"
    tags = [
      { key = "CostCenter", value = "STG-EXAMPLE" },
    ]
  },
]

# 示例已有账号；账号名和账号 ID 均为占位值，部署前替换为已加入组织的真实账号。
existing_organization_account_ids = {
  ci-existing-ops = "2000000000000"
}

cloud_identity_users = [
  {
    key                     = "platform_admin"
    user_name               = "ciAdminExample"
    display_name            = "CI Platform Admin (Example)"
    description             = "平台管理员"
    email                   = ""
    phone                   = ""
    password_reset_required = true
  },
  {
    key                     = "auditor"
    user_name               = "ciAuditorExample"
    display_name            = "CI Security Auditor (Example)"
    description             = "安全审计员"
    email                   = ""
    phone                   = ""
    password_reset_required = true
  },
]

# 部署前填写初始密码；密码须为 8–32 位并满足至少三类复杂度要求。
# 不要提交包含真实密码的文件。
cloud_identity_user_passwords = {
  platform_admin = "ReplaceMe@1234"
  auditor        = "ReplaceMe@1234"
}

cloud_identity_groups = [
  {
    key          = "grp_platform_admin"
    group_name   = "CIAdminsExample"
    display_name = "CI Platform Admins (Example)"
    description  = "平台管理员组"
    join_type    = "Manual"
    member_keys  = ["platform_admin"]
  },
  {
    key          = "grp_security_audit"
    group_name   = "CIAuditorsExample"
    display_name = "CI Security Auditors (Example)"
    description  = "安全审计组"
    join_type    = "Manual"
    member_keys  = ["auditor"]
  },
]

permission_sets = [
  {
    key              = "ps_admin"
    name             = "CIPlatformAdminExample"
    description      = "平台管理权限"
    session_duration = 3600
    relay_state      = "https://console.volcengine.com/"
    permission_policies = [
      {
        permission_policy_name     = "AdministratorAccess"
        permission_policy_type     = "System"
        permission_policy_document = ""
      },
    ]
  },
  {
    key              = "ps_readonly"
    name             = "CISecurityReadExample"
    description      = "安全审计只读权限"
    session_duration = 7200
    relay_state      = "https://console.volcengine.com/"
    permission_policies = [
      {
        permission_policy_name     = "ReadOnlyAccess"
        permission_policy_type     = "System"
        permission_policy_document = ""
      },
    ]
  },
]

# 同时配置新建账号和已有账号授权。
# 预期：
#   ciAdminExample 可见 ci-example-ops + ci-existing-ops（管理员）
#   ciAuditorExample 可见 ci-example-prod + ci-existing-ops（只读）
permission_set_assignments = [
  {
    permission_set_key = "ps_admin"
    principal_type     = "Group"
    principal_key      = "grp_platform_admin"
    target_account_key = "ci-example-ops"
  },
  {
    permission_set_key = "ps_readonly"
    principal_type     = "Group"
    principal_key      = "grp_security_audit"
    target_account_key = "ci-example-prod"
  },
  {
    permission_set_key = "ps_admin"
    principal_type     = "Group"
    principal_key      = "grp_platform_admin"
    target_account_key = "ci-existing-ops"
  },
  {
    permission_set_key = "ps_readonly"
    principal_type     = "Group"
    principal_key      = "grp_security_audit"
    target_account_key = "ci-existing-ops"
  },
]
