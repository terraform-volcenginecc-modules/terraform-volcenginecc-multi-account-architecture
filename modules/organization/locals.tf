locals {
  ou_map = { for ou in var.organization_units : ou.key => ou }

  ou_core       = { for key, ou in local.ou_map : key => ou if key == "ou_core" }
  ou_workloads  = { for key, ou in local.ou_map : key => ou if key == "ou_workloads" }
  ou_production = { for key, ou in local.ou_map : key => ou if key == "ou_production" }

  organization_unit_ids = merge(
    { for key, ou in volcenginecc_organization_unit.core : key => ou.org_unit_id },
    { for key, ou in volcenginecc_organization_unit.workloads : key => ou.org_unit_id },
    { for key, ou in volcenginecc_organization_unit.production : key => ou.org_unit_id },
  )

  organization_account_ids = { for key, account in volcenginecc_organization_account.this : key => account.account_id }
}
