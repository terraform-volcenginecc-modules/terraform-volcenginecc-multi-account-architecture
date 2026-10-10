# ==============================================================================
# identity-source 模块变量
# ==============================================================================

variable "identity_provider_name" {
  type        = string
  description = "SAML 身份提供商名称（在云身份中心控制台配置的名称）"
  default     = ""
}

variable "identity_source_mode" {
  type        = string
  description = "身份源模式：local、saml 或 saml_scim"
  default     = "saml_scim"

  validation {
    condition     = contains(["local", "saml", "saml_scim"], var.identity_source_mode)
    error_message = "identity_source_mode 必须是 local、saml 或 saml_scim"
  }
}

variable "saml_configured" {
  type        = bool
  description = "SAML 身份提供商是否已在控制台配置完成"
  default     = false
}

variable "scim_configured" {
  type        = bool
  description = "SCIM 同步是否已在控制台启用并配置完成"
  default     = false
}

variable "skip_identity_source_gate" {
  type        = bool
  description = "是否跳过身份源配置门禁（仅测试环境使用，生产环境保持 false）"
  default     = false
}
