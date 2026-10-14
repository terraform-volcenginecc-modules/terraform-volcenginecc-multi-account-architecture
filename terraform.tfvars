# 示例配置：创建 5 个新账号，并复用 5 个已有账号做权限授权。
# 已有账号只通过 ID 引用，不管理其 OU、标签或生命周期。所有空值必须在部署前填写。
region         = "cn-beijing"
project        = "example-multi-account"
environment    = "example"
root_parent_id = ""

organization_units = [
  {
    key           = "ou_core"
    name          = "Example-Core"
    description   = "运维、安全、日志等核心账号"
    parent_ou_key = ""
  },
  {
    key           = "ou_workloads"
    name          = "Example-Workloads"
    description   = "业务负载账号"
    parent_ou_key = ""
  },
  {
    key           = "ou_production"
    name          = "Example-Production"
    description   = "生产环境"
    parent_ou_key = "ou_workloads"
  },
]

organization_accounts = [
  {
    account_name             = "example-operation"
    show_name                = "example-operation"
    description              = "运维管理账号"
    org_unit_key             = "ou_core"
    allow_console            = 1
    verification_relation_id = ""
    account_type             = "operation"
    tags = [
      { key = "CostCenter", value = "OPS-001" },
    ]
  },
  {
    account_name             = "example-security"
    show_name                = "example-security"
    description              = "安全审计账号"
    org_unit_key             = "ou_core"
    allow_console            = 1
    verification_relation_id = ""
    account_type             = "security"
    tags = [
      { key = "CostCenter", value = "SEC-001" },
    ]
  },
  {
    account_name             = "example-logging"
    show_name                = "example-logging"
    description              = "日志归集账号"
    org_unit_key             = "ou_core"
    allow_console            = 1
    verification_relation_id = ""
    account_type             = "logging"
    tags = [
      { key = "CostCenter", value = "LOG-001" },
    ]
  },
  {
    account_name             = "example-production"
    show_name                = "example-production"
    description              = "生产业务账号"
    org_unit_key             = "ou_production"
    allow_console            = 1
    verification_relation_id = ""
    account_type             = "production"
    tags = [
      { key = "CostCenter", value = "PROD-001" },
    ]
  },
  {
    account_name             = "example-staging"
    show_name                = "example-staging"
    description              = "预发测试账号"
    org_unit_key             = "ou_workloads"
    allow_console            = 1
    verification_relation_id = ""
    account_type             = "staging"
    tags = [
      { key = "CostCenter", value = "STG-001" },
    ]
  },
]

existing_organization_account_ids = {
  existing-operation  = ""
  existing-security   = ""
  existing-logging    = ""
  existing-production = ""
  existing-staging    = ""
}

cloud_identity_users = [
  {
    key                     = "platform_admin"
    user_name               = "exampleAdmin01"
    display_name            = "Example Platform Admin"
    description             = "平台管理员"
    email                   = "platform-admin@example.com"
    phone                   = ""
    password_reset_required = true
  },
  {
    key                     = "auditor"
    user_name               = "exampleAuditor01"
    display_name            = "Example Security Auditor"
    description             = "安全审计员"
    email                   = "security-auditor@example.com"
    phone                   = ""
    password_reset_required = true
  },
]

# 部署前填写初始密码；密码须为 8–32 位并满足至少三类复杂度要求。
# 不要提交包含真实密码的文件。
cloud_identity_user_passwords = {
  platform_admin = ""
  auditor        = ""
}

cloud_identity_groups = [
  {
    key          = "grp_platform_admin"
    group_name   = "ExampleAdmins01"
    display_name = "Example Platform Admins"
    description  = "平台管理员组"
    join_type    = "Manual"
    member_keys  = ["platform_admin"]
  },
  {
    key          = "grp_security_audit"
    group_name   = "ExampleAuditors01"
    display_name = "Example Security Auditors"
    description  = "安全审计组"
    join_type    = "Manual"
    member_keys  = ["auditor"]
  },
]

permission_sets = [
  {
    key              = "ps_admin"
    name             = "ExamplePlatformAdmin"
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
    name             = "ExampleSecurityRead"
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
#   exampleAdmin01 可见 example-operation + existing-operation（管理员）
#   exampleAuditor01 可见 example-production + existing-production（只读）
permission_set_assignments = [
  {
    permission_set_key = "ps_admin"
    principal_type     = "Group"
    principal_key      = "grp_platform_admin"
    target_account_key = "example-operation"
  },
  {
    permission_set_key = "ps_readonly"
    principal_type     = "Group"
    principal_key      = "grp_security_audit"
    target_account_key = "example-production"
  },
  {
    permission_set_key = "ps_admin"
    principal_type     = "Group"
    principal_key      = "grp_platform_admin"
    target_account_key = "existing-operation"
  },
  {
    permission_set_key = "ps_readonly"
    principal_type     = "Group"
    principal_key      = "grp_security_audit"
    target_account_key = "existing-production"
  },
]
