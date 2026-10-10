# ==============================================================================
# 模块：cloud-identity-group
# 功能：云身份中心用户组封装，按职能批量授权
# 描述：通过用户组承载"通用职能权限"（如运维、研发、安全），
#       新员工加入对应组即继承所有授权，降低权限运维成本。
# 典型场景：
#   - 划分 NetworkOps / DevTeam / SecAdmin 等职能组
#   - 转岗时仅调整成员所属组，无需逐条改授权
# ==============================================================================
resource "volcenginecc_cloudidentity_group" "this" {
  group_name   = var.group_name
  display_name = var.display_name
  description  = var.description
  join_type    = var.join_type

  # 成员列表通过 user_id 关联用户。Manual 类型由 IaC 维护，Auto 类型由身份源同步
  members = [
    for uid in var.member_user_ids : {
      user_id = uid
    }
  ]
}
