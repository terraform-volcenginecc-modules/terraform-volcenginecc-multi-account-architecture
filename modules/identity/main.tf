resource "volcenginecc_cloudidentity_user" "this" {
  for_each = local.users_by_key

  user_name               = each.value.user_name
  display_name            = each.value.display_name
  description             = each.value.description
  email                   = each.value.email
  phone                   = each.value.phone
  password                = lookup(var.cloud_identity_user_passwords, each.key, "")
  password_reset_required = each.value.password_reset_required

  lifecycle {
    precondition {
      condition = (
        length(lookup(var.cloud_identity_user_passwords, each.key, "")) >= 8 &&
        length(lookup(var.cloud_identity_user_passwords, each.key, "")) <= 32 &&
        length([
          for pattern in ["[A-Z]", "[a-z]", "[0-9]", "[^A-Za-z0-9[:space:]]"] : pattern
          if length(regexall(pattern, lookup(var.cloud_identity_user_passwords, each.key, ""))) > 0
        ]) >= 3
      )
      error_message = "每个用户必须提供 8–32 位密码，包含大写、小写、数字、特殊字符中的至少三类。"
    }
  }
}

resource "volcenginecc_cloudidentity_group" "this" {
  for_each = local.groups_by_key

  group_name   = each.value.group_name
  display_name = each.value.display_name
  description  = each.value.description
  join_type    = each.value.join_type
  members = [
    for member_key in each.value.member_keys : {
      user_id = volcenginecc_cloudidentity_user.this[member_key].user_id
    }
  ]

  lifecycle {
    precondition {
      condition = (
        alltrue([for key in each.value.member_keys : contains(keys(local.users_by_key), key)]) &&
        length(each.value.member_keys) == length(distinct(each.value.member_keys))
      )
      error_message = "用户组 member_keys 必须引用已定义的用户 key，且不能重复。"
    }
  }
}
