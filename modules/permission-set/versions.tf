# 模块版本约束：子模块只声明 Provider 依赖，不重复 Provider 配置
terraform {
  required_providers {
    volcenginecc = {
      source  = "volcengine/volcenginecc"
      version = "= 0.0.70"
    }
  }
}
