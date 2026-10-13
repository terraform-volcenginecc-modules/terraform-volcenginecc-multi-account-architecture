resource "terraform_data" "configuration_guard" {
  input = "validated"

  lifecycle {
    precondition {
      condition     = length(var.organization_units) == length(distinct([for ou in var.organization_units : ou.key]))
      error_message = "organization_units.key 必须唯一"
    }

    precondition {
      condition = alltrue([
        for ou in var.organization_units :
        ou.parent_ou_key == "" || (ou.parent_ou_key != ou.key && contains(keys(local.ou_map), ou.parent_ou_key))
      ])
      error_message = "每个非根级 OU 必须引用另一个已声明 OU"
    }

    precondition {
      condition = length(var.organization_units) == 0 || (
        length(var.organization_units) == 3
        && try(local.ou_map["ou_core"].parent_ou_key, null) == ""
        && try(local.ou_map["ou_workloads"].parent_ou_key, null) == ""
        && try(local.ou_map["ou_production"].parent_ou_key, null) == "ou_workloads"
      )
      error_message = "organization_units 必须为空，或使用固定拓扑：ou_core、ou_workloads 挂根节点，ou_production 挂 ou_workloads"
    }

    precondition {
      condition     = length(var.organization_accounts) == length(distinct([for account in var.organization_accounts : account.account_name]))
      error_message = "organization_accounts.account_name 必须唯一"
    }

    precondition {
      condition = alltrue([
        for account in var.organization_accounts :
        account.org_unit_key == "" || contains(keys(local.ou_map), account.org_unit_key)
      ])
      error_message = "organization_accounts.org_unit_key 必须引用已声明 OU"
    }

    precondition {
      condition     = length(var.cloud_identity_users) == length(distinct([for user in var.cloud_identity_users : user.key]))
      error_message = "cloud_identity_users.key 必须唯一"
    }

    precondition {
      condition = alltrue([
        for user in var.cloud_identity_users :
        try(trimspace(var.cloud_identity_user_passwords[user.key]) != "", false)
      ])
      error_message = "cloud_identity_user_passwords 必须为每个 cloud_identity_users 用户提供非空初始密码"
    }

    precondition {
      condition     = length(var.cloud_identity_groups) == length(distinct([for group in var.cloud_identity_groups : group.key]))
      error_message = "cloud_identity_groups.key 必须唯一"
    }

    precondition {
      condition = alltrue([
        for group in var.cloud_identity_groups :
        alltrue([for member_key in group.member_keys : contains(keys(local.users_by_key), member_key)])
      ])
      error_message = "cloud_identity_groups.member_keys 必须引用 Terraform 管理的用户"
    }

    precondition {
      condition     = length(var.permission_sets) == length(distinct([for permission_set in var.permission_sets : permission_set.key]))
      error_message = "permission_sets.key 必须唯一"
    }

    precondition {
      condition = length(setintersection(
        toset(keys(var.external_principals)),
        setunion(toset(keys(local.users_by_key)), toset(keys(local.groups_by_key)))
      )) == 0
      error_message = "external_principals 的 key 不得与 Terraform 管理的用户或组重复"
    }

    precondition {
      condition = alltrue([
        for assignment in var.permission_set_assignments :
        contains(keys(local.permission_sets_by_key), assignment.permission_set_key) &&
        (
          assignment.target_account_key == "" ||
          contains(keys(local.organization_account_ids), assignment.target_account_key)
        ) &&
        (
          assignment.principal_type == "User"
          ? contains(keys(local.users_by_key), assignment.principal_key) || try(var.external_principals[assignment.principal_key].principal_type, "") == "User"
          : contains(keys(local.groups_by_key), assignment.principal_key) || try(var.external_principals[assignment.principal_key].principal_type, "") == "Group"
        )
      ])
      error_message = "访问授权引用了不存在或类型不匹配的权限集、主体或目标账号"
    }
  }
}
