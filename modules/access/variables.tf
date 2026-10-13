variable "assignments" {
  type        = map(object({ permission_set_key = string, principal_type = string, principal_key = string, target_account_key = string }))
  description = "Validated authorization triples with stable keys"
}
variable "provisioning_targets" {
  type        = map(object({ permission_set_key = string, target_account_key = string }))
  description = "Distinct permission-set/account pairs synchronized after assignment"
}
variable "account_ids" {
  type        = map(string)
  description = "Resolved organization account IDs"
}
variable "principal_ids" {
  type        = map(string)
  description = "Resolved principal IDs indexed by type:key"
}
variable "permission_set_ids" {
  type        = map(string)
  description = "Resolved permission-set IDs"
}
