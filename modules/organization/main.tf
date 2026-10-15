# Organization creates OUs and member accounts directly.
# Enterprise Organization rejects concurrent OU mutations. Keep each OU in a
# separate resource so Terraform's dependency graph serializes the API calls.
resource "volcenginecc_organization_unit" "core" {
  for_each = local.ou_core

  parent_id   = var.root_parent_id
  name        = each.value.name
  description = each.value.description
}

resource "volcenginecc_organization_unit" "workloads" {
  for_each = local.ou_workloads

  parent_id   = var.root_parent_id
  name        = each.value.name
  description = each.value.description

  depends_on = [volcenginecc_organization_unit.core]
}

resource "volcenginecc_organization_unit" "production" {
  for_each = local.ou_production

  parent_id   = volcenginecc_organization_unit.workloads[each.value.parent_ou_key].org_unit_id
  name        = each.value.name
  description = each.value.description

  depends_on = [volcenginecc_organization_unit.workloads]
}

resource "volcenginecc_organization_account" "this" {
  for_each = { for account in var.organization_accounts : account.account_name => account }

  account_name             = each.value.account_name
  show_name                = each.value.show_name != "" ? each.value.show_name : each.value.account_name
  description              = each.value.description
  org_unit_id              = each.value.org_unit_key == "" ? var.root_parent_id : local.organization_unit_ids[each.value.org_unit_key]
  allow_console            = each.value.allow_console
  verification_relation_id = each.value.verification_relation_id == "" ? null : each.value.verification_relation_id
  tags = [for key, value in merge(
    { for tag in each.value.tags : tag.key => tag.value },
    { for tag in var.common_tags : tag.key => tag.value },
    { AccountType = each.value.account_type }
  ) : { key = key, value = value }]

  lifecycle {
    precondition {
      condition     = !contains(var.existing_account_names, each.value.account_name)
      error_message = "新建账号 ${each.value.account_name} 与已有账号同名，请修改 organization_accounts 或 existing_organization_account_ids"
    }

    precondition {
      condition     = each.value.org_unit_key == "" || contains(keys(local.ou_map), each.value.org_unit_key)
      error_message = "账号 org_unit_key 必须引用已声明 OU；空值表示组织根节点"
    }
  }
}
