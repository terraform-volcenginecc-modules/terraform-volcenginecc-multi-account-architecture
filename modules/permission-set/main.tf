# ==============================================================================
# 模块：permission-set
# 功能：云身份中心访问权限集（Permission Set）封装
# 描述：权限集是访问火山引擎账号时的权限模板，可由若干 System 策略 + Inline 策略组成。
#       支持在多个账号下集中管理同一份权限集，通过 Provisioning 下发到目标账号。
# 设计要点：
#   - permission_policies 是 SetNestedAttribute，必须完整定义所有字段（包括 Inline 留空字符串）
#   - session_duration 单位为秒，建议 3600 或更长以适配长会话场景
#   - 权限集创建后，通过 access 模块先授权再同步；策略更新后需确认目标账号同步状态
# ==============================================================================
resource "volcenginecc_cloudidentity_permission_set" "this" {
  name             = var.name
  description      = var.description
  session_duration = var.session_duration
  relay_state      = var.relay_state != "" ? var.relay_state : "https://console.volcengine.com/"

  # 完整声明所有字段，避免 plan 出现非预期 diff
  permission_policies = [
    for p in var.permission_policies : {
      permission_policy_name     = p.permission_policy_name
      permission_policy_type     = p.permission_policy_type
      permission_policy_document = p.permission_policy_document
    }
  ]
}
