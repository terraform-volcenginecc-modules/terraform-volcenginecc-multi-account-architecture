locals {
  common_tags = [
    { key = "Project", value = var.project },
    { key = "Environment", value = var.environment },
    { key = "ManagedBy", value = "terraform" },
  ]

  ou_map = { for ou in var.organization_units : ou.key => ou }

  ou_core       = { for key, ou in local.ou_map : key => ou if key == "ou_core" }
  ou_workloads  = { for key, ou in local.ou_map : key => ou if key == "ou_workloads" }
  ou_production = { for key, ou in local.ou_map : key => ou if key == "ou_production" }

  organization_unit_ids = merge(
    { for key, ou in volcenginecc_organization_unit.core : key => ou.org_unit_id },
    { for key, ou in volcenginecc_organization_unit.workloads : key => ou.org_unit_id },
    { for key, ou in volcenginecc_organization_unit.production : key => ou.org_unit_id },
  )

  organization_account_ids = {
    for key, account in module.organization_accounts : key => account.account_id
  }

  users_by_key           = { for user in var.cloud_identity_users : user.key => user }
  groups_by_key          = { for group in var.cloud_identity_groups : group.key => group }
  permission_sets_by_key = { for permission_set in var.permission_sets : permission_set.key => permission_set }

  assignments = {
    for assignment in var.permission_set_assignments :
    "${assignment.permission_set_key}|${assignment.principal_type}|${assignment.principal_key}|${assignment.target_account_key != "" ? "key:${assignment.target_account_key}" : "id:${assignment.target_account_id}"}" => assignment
  }

  provisioning_keys = toset([
    for assignment in var.permission_set_assignments :
    "${assignment.permission_set_key}|${assignment.target_account_key != "" ? "key:${assignment.target_account_key}" : "id:${assignment.target_account_id}"}"
  ])
}
