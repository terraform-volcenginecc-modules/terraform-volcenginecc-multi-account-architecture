# ==============================================================================
# 模块：cloud-identity-user
# 功能：云身份中心（Cloud Identity）用户封装
# 描述：与企业员工身份一一映射的云身份中心用户，是后续访问授权的 principal。
# 典型场景：
#   - 入职：在 cloud_identity_users 列表中新增条目
#   - 离职：从 cloud_identity_users 列表中删除该条目（Terraform 会自动撤销关联授权）
# 设计要点：
#   - 强制密码重置（password_reset_required=true）以保障首次登录安全
#   - password 字段标记为 sensitive，避免在 plan/apply 输出泄露
# ==============================================================================
resource "volcenginecc_cloudidentity_user" "this" {
  user_name               = var.user_name
  display_name            = var.display_name
  description             = var.description
  email                   = var.email
  phone                   = var.phone
  password                = var.password
  password_reset_required = var.password_reset_required
}
