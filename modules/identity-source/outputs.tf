# ==============================================================================
# identity-source 模块输出
# ==============================================================================

output "identity_provider_name" {
  description = "SAML 身份提供商名称"
  value       = var.identity_provider_name
}

output "identity_source_mode" {
  description = "身份源模式"
  value       = var.identity_source_mode
}

output "saml_configured" {
  description = "SAML 是否配置完成"
  value       = var.saml_configured
}

output "scim_configured" {
  description = "SCIM 是否配置完成"
  value       = var.scim_configured
}

output "gate_passed" {
  description = "身份源门禁是否通过（用于下游模块依赖）"
  value       = terraform_data.identity_source_gate.id != ""
}
