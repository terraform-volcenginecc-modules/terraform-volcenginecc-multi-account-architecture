variable "user_name" {
  type        = string
  description = "云身份中心用户名（唯一）"
}

variable "display_name" {
  type        = string
  description = "用户显示名"
  default     = ""
}

variable "description" {
  type        = string
  description = "用户描述"
  default     = ""
}

variable "email" {
  type        = string
  description = "邮箱地址，用于 SSO 通知与密码找回"
  default     = ""
}

variable "phone" {
  type        = string
  description = "手机号，用于二次验证或登录保护"
  default     = ""
}

variable "password" {
  type        = string
  description = "初始密码，需符合 8-32 字符且包含大小写/数字/特殊字符的至少 3 类"
  default     = ""
  sensitive   = true
}

variable "password_reset_required" {
  type        = bool
  description = "首次登录是否强制重置密码。名称含 password_ 前缀，按机密处理规范标记 sensitive 且不设默认值，由调用方显式传入"
  sensitive   = true
}
