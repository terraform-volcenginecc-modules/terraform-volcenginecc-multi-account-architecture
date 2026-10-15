locals {
  common_tags = [
    { key = "Project", value = var.project },
    { key = "Environment", value = var.environment },
    { key = "ManagedBy", value = "terraform" },
  ]
  all_organization_account_ids = merge(
    module.organization.organization_account_ids,
    var.existing_organization_account_ids,
  )
  permission_sets_by_key = { for ps in var.permission_sets : ps.key => ps }
  assignments = { for assignment in var.permission_set_assignments :
    "${assignment.permission_set_key}|${assignment.principal_type}|${assignment.principal_key}|${assignment.target_account_key}" => assignment
  }
  grouped_targets = { for assignment in var.permission_set_assignments : "${assignment.permission_set_key}|${assignment.target_account_key}" => {
    permission_set_key = assignment.permission_set_key
    target_account_key = assignment.target_account_key
  }... }
  provisioning_targets = { for key, targets in local.grouped_targets : key => targets[0] }
}
