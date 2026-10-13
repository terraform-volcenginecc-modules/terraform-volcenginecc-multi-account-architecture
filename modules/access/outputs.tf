output "assignment_ids" {
  description = "Assignment IDs by stable triple key"
  value       = { for key, a in volcenginecc_cloudidentity_permission_set_assignment.this : key => a.id }
}
output "provisioning_status" {
  description = "Permission-set provisioning status after assignment"
  value       = { for key, p in volcenginecc_cloudidentity_permission_set_provisioning.this : key => p.provisioning_status }
}
