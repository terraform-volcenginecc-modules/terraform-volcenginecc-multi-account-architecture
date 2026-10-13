locals {
  users_by_key  = { for user in var.cloud_identity_users : user.key => user }
  groups_by_key = { for group in var.cloud_identity_groups : group.key => group }
}
