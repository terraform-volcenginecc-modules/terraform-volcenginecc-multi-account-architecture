# T20261014C 混合部署：创建 5 个新账号，并复用 1 个已有账号做权限授权。
# 已有账号只通过 ID 引用，不管理其 OU、标签或生命周期。密码必须在部署前填写。
region         = "cn-beijing"
project        = "default"
environment    = "prod"
root_parent_id = "7696086135349100582"

organization_units = [
  {
    key           = "ou_core"
    name          = "Core-T20261014C"
    description   = "运维、安全、日志等核心账号"
    parent_ou_key = ""
  },
  {
    key           = "ou_workloads"
    name          = "Workloads-T20261014C"
    description   = "业务负载账号"
    parent_ou_key = ""
  },
  {
    key           = "ou_production"
    name          = "Production-T20261014C"
    description   = "生产环境"
    parent_ou_key = "ou_workloads"
  },
]

organization_accounts = [
  {
    account_name             = "ci-t20261014c-ops"
    show_name                = "ci-t20261014c-ops"
    description              = "运维管理账号"
    org_unit_key             = "ou_core"
    allow_console            = 1
    verification_relation_id = ""
    account_type             = "operation"
    tags = [
      { key = "CostCenter", value = "OPS-C01" },
    ]
  },
  {
    account_name             = "ci-t20261014c-sec"
    show_name                = "ci-t20261014c-sec"
    description              = "安全审计账号"
    org_unit_key             = "ou_core"
    allow_console            = 1
    verification_relation_id = ""
    account_type             = "security"
    tags = [
      { key = "CostCenter", value = "SEC-C01" },
    ]
  },
  {
    account_name             = "ci-t20261014c-log"
    show_name                = "ci-t20261014c-log"
    description              = "日志归集账号"
    org_unit_key             = "ou_core"
    allow_console            = 1
    verification_relation_id = ""
    account_type             = "logging"
    tags = [
      { key = "CostCenter", value = "LOG-C01" },
    ]
  },
  {
    account_name             = "ci-t20261014c-prod"
    show_name                = "ci-t20261014c-prod"
    description              = "生产业务账号"
    org_unit_key             = "ou_production"
    allow_console            = 1
    verification_relation_id = ""
    account_type             = "production"
    tags = [
      { key = "CostCenter", value = "PROD-C01" },
    ]
  },
  {
    account_name             = "ci-t20261014c-stg"
    show_name                = "ci-t20261014c-stg"
    description              = "预发测试账号"
    org_unit_key             = "ou_workloads"
    allow_console            = 1
    verification_relation_id = ""
    account_type             = "staging"
    tags = [
      { key = "CostCenter", value = "STG-C01" },
    ]
  },
]

existing_organization_account_ids = {
  ci-t20261010a-ops = "2132837596"
}

cloud_identity_users = [
  {
    key                     = "platform_admin"
    user_name               = "ciAdmin20261014C"
    display_name            = "CI Platform Admin C"
    description             = "平台管理员"
    email                   = ""
    phone                   = ""
    password_reset_required = true
  },
  {
    key                     = "auditor"
    user_name               = "ciAuditor20261014C"
    display_name            = "CI Security Auditor C"
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
    group_name   = "CIAdmins20261014C"
    display_name = "CI Platform Admins C"
    description  = "平台管理员组"
    join_type    = "Manual"
    member_keys  = ["platform_admin"]
  },
  {
    key          = "grp_security_audit"
    group_name   = "CIAuditors20261014C"
    display_name = "CI Security Auditors C"
    description  = "安全审计组"
    join_type    = "Manual"
    member_keys  = ["auditor"]
  },
]

permission_sets = [
  {
    key              = "ps_admin"
    name             = "CIPlatformAdmin20261014C"
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
    name             = "CISecurityRead20261014C"
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
#   ciAdmin20261014C 可见 ci-t20261014c-ops + ci-t20261010a-ops（管理员）
#   ciAuditor20261014C 可见 ci-t20261014c-prod + ci-t20261010a-ops（只读）
permission_set_assignments = [
  {
    permission_set_key = "ps_admin"
    principal_type     = "Group"
    principal_key      = "grp_platform_admin"
    target_account_key = "ci-t20261014c-ops"
  },
  {
    permission_set_key = "ps_readonly"
    principal_type     = "Group"
    principal_key      = "grp_security_audit"
    target_account_key = "ci-t20261014c-prod"
  },
  {
    permission_set_key = "ps_admin"
    principal_type     = "Group"
    principal_key      = "grp_platform_admin"
    target_account_key = "ci-t20261010a-ops"
  },
  {
    permission_set_key = "ps_readonly"
    principal_type     = "Group"
    principal_key      = "grp_security_audit"
    target_account_key = "ci-t20261010a-ops"
  },
]
