output "organization_unit_ids" {
  description = "组织单元 ID 映射"
  value       = local.organization_unit_ids
}

output "organization_account_ids" {
  description = "成员账号 ID 映射"
  value       = local.organization_account_ids
}

output "identity_source_status" {
  description = "身份源配置状态"
  value = {
    mode                   = module.identity_source.identity_source_mode
    identity_provider_name = module.identity_source.identity_provider_name
    saml_configured        = module.identity_source.saml_configured
    scim_configured        = module.identity_source.scim_configured
    gate_passed            = module.identity_source.gate_passed
  }
}

output "cloud_identity_user_ids" {
  description = "云身份中心用户 ID 映射"
  value       = { for key, user in module.cloud_identity_users : key => user.user_id }
}

output "cloud_identity_group_ids" {
  description = "云身份中心用户组 ID 映射"
  value       = { for key, group in module.cloud_identity_groups : key => group.group_id }
}

output "permission_set_ids" {
  description = "权限集 ID 映射"
  value       = { for key, permission_set in module.permission_sets : key => permission_set.permission_set_id }
}

output "permission_set_assignment_ids" {
  description = "访问授权 ID 映射"
  value = {
    for key, assignment in volcenginecc_cloudidentity_permission_set_assignment.this :
    key => assignment.id
  }
}

output "permission_set_provisioning_status" {
  description = "权限集目标账号部署状态"
  value = {
    for key, provisioning in volcenginecc_cloudidentity_permission_set_provisioning.this :
    key => provisioning.provisioning_status
  }
}
