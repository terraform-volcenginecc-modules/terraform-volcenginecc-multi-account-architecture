# Cross-input diagnostics only; check assertions do not add managed resources.
# Terraform check failures are warnings. Invalid inputs are also rejected by
# variable validation or the relevant cloud resource's lifecycle.precondition.
check "account_ou_references" {
  assert {
    condition = alltrue([
      for account in var.organization_accounts :
      account.org_unit_key == "" || contains([for ou in var.organization_units : ou.key], account.org_unit_key)
    ])
    error_message = "organization_accounts.org_unit_key 必须引用已声明 OU；空值表示组织根节点"
  }
}

check "account_key_conflicts" {
  assert {
    condition = length(setintersection(
      toset([for account in var.organization_accounts : account.account_name]),
      toset(keys(var.existing_organization_account_ids)),
    )) == 0
    error_message = "新建账号与已有账号不能使用相同的 account_name"
  }
}

check "user_passwords_complete" {
  assert {
    condition = alltrue([
      for user in var.cloud_identity_users : contains(keys(var.cloud_identity_user_passwords), user.key)
    ])
    error_message = "cloud_identity_user_passwords 必须为每个已声明用户提供初始密码"
  }
}

check "group_member_references" {
  assert {
    condition = alltrue([
      for group in var.cloud_identity_groups : alltrue([
        for member_key in group.member_keys : contains([for user in var.cloud_identity_users : user.key], member_key)
      ])
    ])
    error_message = "cloud_identity_groups.member_keys 必须引用已声明的用户 key"
  }
}

check "assignment_references" {
  assert {
    condition = alltrue([
      for assignment in var.permission_set_assignments :
      contains([for permission_set in var.permission_sets : permission_set.key], assignment.permission_set_key) &&
      contains(concat(
        [for account in var.organization_accounts : account.account_name],
        keys(var.existing_organization_account_ids),
      ), assignment.target_account_key) &&
      (
        assignment.principal_type == "User"
        ? contains([for user in var.cloud_identity_users : user.key], assignment.principal_key)
        : assignment.principal_type == "Group" && contains([for group in var.cloud_identity_groups : group.key], assignment.principal_key)
      )
    ])
    error_message = "访问授权必须引用已声明的权限集、账号以及类型匹配的用户或用户组"
  }
}
