variable "group_name" {
  type        = string
  description = "用户组名称（唯一）"
}

variable "display_name" {
  type        = string
  description = "用户组显示名"
  default     = ""
}

variable "description" {
  type        = string
  description = "用户组描述"
  default     = ""
}

variable "join_type" {
  type        = string
  description = "用户组类型：Manual（手动维护成员）或 Auto（身份源自动同步）"
  default     = "Manual"

  validation {
    condition     = contains(["Manual", "Auto"], var.join_type)
    error_message = "join_type 必须是 Manual 或 Auto"
  }
}

variable "member_user_ids" {
  type        = list(string)
  description = "成员用户 ID 列表（cloud_identity_user 的 user_id）"
  default     = []
}
