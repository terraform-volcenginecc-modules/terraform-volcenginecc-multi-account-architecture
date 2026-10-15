# Wait for newly-created organization accounts to become visible to Cloud Identity.
resource "time_sleep" "cloud_identity_account_propagation" {
  count           = length(var.assignments) > 0 ? 1 : 0
  create_duration = "180s"

  # All account IDs are available only after their creation has completed.
  # The sequence version forces replacement of the former 60-second wait.
  triggers = {
    account_ids      = join(",", sort(values(var.account_ids)))
    sequence_version = "assignment-provisioning-v2-180s"
  }
}

resource "volcenginecc_cloudidentity_permission_set_assignment" "this" {
  for_each          = var.assignments
  permission_set_id = lookup(var.permission_set_ids, each.value.permission_set_key, null)
  principal_type    = each.value.principal_type
  principal_id      = lookup(var.principal_ids, "${each.value.principal_type}:${each.value.principal_key}", null)
  target_id         = lookup(var.account_ids, each.value.target_account_key, null)
  depends_on        = [time_sleep.cloud_identity_account_propagation]

  lifecycle {
    precondition {
      condition = (
        contains(keys(var.permission_set_ids), each.value.permission_set_key) &&
        contains(["User", "Group"], each.value.principal_type) &&
        contains(keys(var.principal_ids), "${each.value.principal_type}:${each.value.principal_key}") &&
        contains(keys(var.account_ids), each.value.target_account_key)
      )
      error_message = "访问授权必须引用已声明的权限集、目标账号以及类型匹配的用户或用户组"
    }
  }
}

resource "volcenginecc_cloudidentity_permission_set_provisioning" "this" {
  for_each          = var.provisioning_targets
  permission_set_id = lookup(var.permission_set_ids, each.value.permission_set_key, null)
  target_id         = lookup(var.account_ids, each.value.target_account_key, null)
  depends_on        = [volcenginecc_cloudidentity_permission_set_assignment.this]

  lifecycle {
    precondition {
      condition = (
        contains(keys(var.permission_set_ids), each.value.permission_set_key) &&
        contains(keys(var.account_ids), each.value.target_account_key)
      )
      error_message = "权限集同步必须引用已声明的权限集和目标账号"
    }
  }
}
