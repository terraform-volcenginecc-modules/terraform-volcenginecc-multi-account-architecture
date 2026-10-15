# Root orchestration for the seven cloud resource types.
module "organization" {
  source                 = "./modules/organization"
  root_parent_id         = var.root_parent_id
  organization_units     = var.organization_units
  organization_accounts  = var.organization_accounts
  existing_account_names = toset(keys(var.existing_organization_account_ids))
  common_tags            = local.common_tags
}

module "identity" {
  source                        = "./modules/identity"
  cloud_identity_users          = var.cloud_identity_users
  cloud_identity_user_passwords = var.cloud_identity_user_passwords
  cloud_identity_groups         = var.cloud_identity_groups
}

module "permission_sets" {
  source              = "./modules/permission-set"
  for_each            = local.permission_sets_by_key
  name                = each.value.name
  description         = each.value.description
  session_duration    = each.value.session_duration
  relay_state         = each.value.relay_state
  permission_policies = each.value.permission_policies
}

module "access" {
  source               = "./modules/access"
  assignments          = local.assignments
  provisioning_targets = local.provisioning_targets
  account_ids          = local.all_organization_account_ids
  principal_ids        = module.identity.principal_ids
  permission_set_ids   = { for key, ps in module.permission_sets : key => ps.permission_set_id }
}
