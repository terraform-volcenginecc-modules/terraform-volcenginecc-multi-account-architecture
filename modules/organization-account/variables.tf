variable "account_name" {
  type        = string
  description = "账号名（5-20 字符）"
}

variable "show_name" {
  type        = string
  description = "账号显示名"
}

variable "description" {
  type        = string
  description = "账号描述"
  default     = ""
}

variable "org_unit_id" {
  type        = string
  description = "所属组织单元 ID"
}

variable "allow_console" {
  type        = number
  description = "是否允许控制台登录：1 允许 / 2 不允许"
  default     = 1
}

variable "verification_relation_id" {
  type        = string
  description = "继承的认证主体 ID。单主体场景留空，使用管理员账号默认认证主体"
  default     = ""
}

variable "tags" {
  type = list(object({
    key   = string
    value = string
  }))
  description = "资源标签"
  default     = []
}
