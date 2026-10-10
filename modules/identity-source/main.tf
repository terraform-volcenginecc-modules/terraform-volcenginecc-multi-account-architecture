# ==============================================================================
# 模块：identity-source
# 功能：云身份中心身份源（SAML 单点登录 + SCIM 自动同步）配置门禁
# 描述：volcenginecc Provider 暂不提供 SAML 身份提供商与 SCIM 同步资源，
#       本模块以"人工操作卡片 + Terraform 门禁"的形式管理这两项配置：
#         1. SAML：在云身份中心控制台配置 SAML 身份提供商
#            （上传 IdP metadata 文档，或手动填写 EntityId / LoginUrl / X509 证书）
#         2. SCIM：启用 SCIM 同步并获取 SCIM Server 凭证（Base URL + Token）
#            供 HR/IdP 系统推送用户与用户组
# 本模块不创建任何云资源，仅在 saml_configured / scim_configured 均为 true 时放行。
# ==============================================================================

resource "terraform_data" "identity_source_gate" {
  # 用身份提供商名称作为稳定触发器
  triggers_replace = [var.identity_source_mode, var.identity_provider_name]

  lifecycle {
    precondition {
      condition = (
        var.skip_identity_source_gate ||
        var.identity_source_mode == "local" ||
        (var.identity_source_mode == "saml" && var.saml_configured) ||
        (var.identity_source_mode == "saml_scim" && var.saml_configured && var.scim_configured)
      )
      error_message = <<EOT
云身份中心身份源尚未满足模式 "${var.identity_source_mode}" 的配置要求。

SAML 配置步骤：
  1. 云身份中心控制台 → 身份提供商 → 添加 SAML 提供商
  2. 上传 IdP metadata 文档，或手动填写：
     - EntityId（IdP 实体 ID）
     - LoginUrl（SSO 登录地址）
     - X509 证书（IdP 签名证书）
  3. 将生成的 SP metadata 回调配置到 IdP 侧

SCIM 配置步骤：
  1. 云身份中心控制台 → 设置 → SCIM 同步 → 启用
  2. 获取 SCIM Base URL 与 Access Token，配置到 HR/IdP 系统
  3. 验证用户/组同步链路可用

local 模式无需外部身份源；saml 模式需将 saml_configured 置为 true；
saml_scim 模式需同时将 saml_configured 与 scim_configured 置为 true。
若为测试环境，可设置 skip_identity_source_gate = true 跳过此门禁。
EOT
    }
  }
}
