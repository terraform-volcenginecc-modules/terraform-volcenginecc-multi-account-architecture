output "organization_unit_ids" {
  description = "组织单元 ID 映射"
  value       = module.organization.organization_unit_ids
}

output "organization_account_ids" {
  description = "新建与已有成员账号的统一 ID 映射"
  value       = local.all_organization_account_ids
}

output "cloud_identity_user_ids" {
  description = "云身份中心用户 ID 映射"
  value       = module.identity.user_ids
}

output "cloud_identity_group_ids" {
  description = "云身份中心用户组 ID 映射"
  value       = module.identity.group_ids
}

output "permission_set_ids" {
  description = "权限集 ID 映射"
  value       = { for key, permission_set in module.permission_sets : key => permission_set.permission_set_id }
}

output "permission_set_assignment_ids" {
  description = "访问授权 ID 映射"
  value       = module.access.assignment_ids
}

output "permission_set_provisioning_status" {
  description = "访问授权完成后的权限集同步状态"
  value       = module.access.provisioning_status
}
