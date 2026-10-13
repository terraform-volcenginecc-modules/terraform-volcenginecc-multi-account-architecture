variable "cloud_identity_users" {
  type = list(object({
    key                     = string
    user_name               = string
    display_name            = optional(string, "")
    description             = optional(string, "")
    email                   = optional(string, "")
    phone                   = optional(string, "")
    password_reset_required = optional(bool, true)
  }))
  description = "Terraform 管理的云身份中心用户"
  default     = []
}

variable "cloud_identity_user_passwords" {
  type        = map(string)
  description = "用户初始密码映射，key 对应 cloud_identity_users.key"
  default     = {}
  sensitive   = true
}

variable "cloud_identity_groups" {
  type = list(object({
    key          = string
    group_name   = string
    display_name = optional(string, "")
    description  = optional(string, "")
    join_type    = optional(string, "Manual")
    member_keys  = optional(list(string), [])
  }))
  description = "Terraform 管理的云身份中心用户组"
  default     = []

  validation {
    condition     = alltrue([for group in var.cloud_identity_groups : group.join_type == "Manual"])
    error_message = "Terraform 管理的用户组必须使用 Manual。"
  }
}
