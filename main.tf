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

# Preserve existing deployments after splitting the former for_each resources.
moved {
  from = volcenginecc_organization_unit.level1["ou_core"]
  to   = volcenginecc_organization_unit.core["ou_core"]
}

moved {
  from = volcenginecc_organization_unit.level1["ou_workloads"]
  to   = volcenginecc_organization_unit.workloads["ou_workloads"]
}

moved {
  from = volcenginecc_organization_unit.level2["ou_production"]
  to   = volcenginecc_organization_unit.production["ou_production"]
}

module "organization_accounts" {
  source   = "./modules/account-onboarding"
  for_each = { for account in var.organization_accounts : account.account_name => account }

  mode                         = each.value.mode
  account_name                 = each.value.account_name
  show_name                    = each.value.show_name
  description                  = each.value.description
  org_unit_id                  = each.value.org_unit_key == "" ? var.root_parent_id : local.organization_unit_ids[each.value.org_unit_key]
  allow_console                = each.value.allow_console
  verification_relation_id     = each.value.verification_relation_id
  account_type                 = each.value.account_type
  existing_account_id          = each.value.existing_account_id
  financial_relation_verified  = each.value.financial_relation_verified
  skip_financial_relation_gate = var.skip_financial_relation_gate
  tags                         = concat(each.value.tags, local.common_tags)
}

module "identity_source" {
  source = "./modules/identity-source"

  identity_source_mode      = var.identity_source_mode
  identity_provider_name    = var.identity_provider_name
  saml_configured           = var.saml_configured
  scim_configured           = var.scim_configured
  skip_identity_source_gate = var.skip_identity_source_gate
}

module "cloud_identity_users" {
  source   = "./modules/cloud-identity-user"
  for_each = local.users_by_key

  user_name               = each.value.user_name
  display_name            = each.value.display_name
  description             = each.value.description
  email                   = each.value.email
  phone                   = each.value.phone
  password                = lookup(var.cloud_identity_user_passwords, each.key, "")
  password_reset_required = each.value.password_reset_required

  depends_on = [module.identity_source]
}

module "cloud_identity_groups" {
  source   = "./modules/cloud-identity-group"
  for_each = local.groups_by_key

  group_name   = each.value.group_name
  display_name = each.value.display_name
  description  = each.value.description
  join_type    = each.value.join_type
  member_user_ids = [
    for member_key in each.value.member_keys : module.cloud_identity_users[member_key].user_id
  ]

  depends_on = [module.identity_source]
}

module "permission_sets" {
  source   = "./modules/permission-set"
  for_each = local.permission_sets_by_key

  name                = each.value.name
  description         = each.value.description
  session_duration    = each.value.session_duration
  relay_state         = each.value.relay_state
  permission_policies = each.value.permission_policies
}

# Organization account creation can complete before the account is visible to
# Cloud Identity. Wait once per account set before provisioning permission sets.
resource "time_sleep" "cloud_identity_account_propagation" {
  count = (
    length([for account in var.organization_accounts : account if account.mode == "create"]) > 0 &&
    length(local.provisioning_keys) > 0
  ) ? 1 : 0

  create_duration = var.cloud_identity_account_propagation_wait
  triggers = {
    account_ids = join(",", sort([
      for account in var.organization_accounts :
      local.organization_account_ids[account.account_name]
      if account.mode == "create"
    ]))
  }

  depends_on = [module.organization_accounts]
}

resource "volcenginecc_cloudidentity_permission_set_assignment" "this" {
  for_each = local.assignments

  permission_set_id = module.permission_sets[each.value.permission_set_key].permission_set_id
  principal_type    = each.value.principal_type
  principal_id = each.value.principal_type == "User" ? (
    contains(keys(local.users_by_key), each.value.principal_key)
    ? module.cloud_identity_users[each.value.principal_key].user_id
    : var.external_principals[each.value.principal_key].principal_id
    ) : (
    contains(keys(local.groups_by_key), each.value.principal_key)
    ? module.cloud_identity_groups[each.value.principal_key].group_id
    : var.external_principals[each.value.principal_key].principal_id
  )
  target_id = each.value.target_account_key != "" ? (
    local.organization_account_ids[each.value.target_account_key]
    ) : (
    each.value.target_account_id
  )

  depends_on = [time_sleep.cloud_identity_account_propagation]
}

# Provisioning synchronizes a permission set after the account assignment exists.
resource "volcenginecc_cloudidentity_permission_set_provisioning" "this" {
  for_each = local.provisioning_keys

  permission_set_id = module.permission_sets[split("|", each.value)[0]].permission_set_id
  target_id = startswith(split("|", each.value)[1], "key:") ? (
    local.organization_account_ids[trimprefix(split("|", each.value)[1], "key:")]
    ) : (
    trimprefix(split("|", each.value)[1], "id:")
  )

  depends_on = [volcenginecc_cloudidentity_permission_set_assignment.this]
}
