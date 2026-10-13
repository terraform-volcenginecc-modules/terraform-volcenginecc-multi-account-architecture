variable "name" {
  type        = string
  description = "权限集名称（唯一）"
}

variable "description" {
  type        = string
  description = "权限集描述"
  default     = ""
}

variable "session_duration" {
  type        = number
  description = "会话有效期（秒），范围 3600 - 43200"
  default     = 3600

  validation {
    condition     = var.session_duration >= 3600 && var.session_duration <= 43200 && floor(var.session_duration) == var.session_duration
    error_message = "session_duration 必须为 3600 到 43200 之间的整数秒"
  }
}

variable "relay_state" {
  type        = string
  description = "登录后默认跳转 URL；空值会规范化为 https://console.volcengine.com/，避免服务端默认值造成重复 Plan"
  default     = ""
}

variable "permission_policies" {
  type = list(object({
    permission_policy_name     = string
    permission_policy_type     = string
    permission_policy_document = string
  }))
  description = "权限策略列表（System 策略名 + Inline 策略 JSON 文档）"
  default     = []
}
