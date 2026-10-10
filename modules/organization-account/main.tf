# ==============================================================================
# 模块：organization-account
# 功能：企业组织成员账号统一管理
# 描述：在指定 OU 下创建成员账号，支持继承认证主体（多主体场景）、控制台访问开关、
#       安全联系人和资源标签。
# 典型场景：
#   - 业务上线时按账号粒度做资源/成本/权限隔离
#   - 多主体集团下指定 verification_relation_id 实现"非管理员主体"的账号创建
# 注意：
#   1. 账号创建后无法直接删除，仅支持标记退出，请谨慎规划。
#   2. verification_relation_id 是 uint64，为空时必须 omit，不能传空字符串。
# ==============================================================================
resource "volcenginecc_organization_account" "this" {
  account_name  = var.account_name
  show_name     = var.show_name
  description   = var.description
  org_unit_id   = var.org_unit_id
  allow_console = var.allow_console

  # 仅在非空时传入 verification_relation_id，避免空字符串触发 uint64 反序列化错误
  verification_relation_id = var.verification_relation_id == "" ? null : var.verification_relation_id

  tags = var.tags
}
