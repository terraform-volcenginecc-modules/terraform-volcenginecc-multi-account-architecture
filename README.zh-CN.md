# 火山引擎多账号身份权限集中管理

[English](README.md) | 简体中文

根目录是唯一 Terraform 入口。一次 Apply、一个 State，通过四个模块创建组织、身份、权限集和访问授权。

## 1. 业务背景

用户加入用户组，权限集定义策略。访问授权决定哪个用户或用户组可以使用哪个权限集访问哪个账号；授权完成后，权限集同步将策略部署到目标账号。

## 2. 方案概述

`organization` 创建 OU 和账号；`identity` 创建用户和用户组；`permission-set` 定义权限；`access` 在账号创建完成后等待 180 秒，先创建访问授权，再同步权限集。

~~~mermaid
flowchart LR
  OU["组织单元 OU"] --> ACCOUNT["组织账号"]
  USER["云身份用户"] --> GROUP["云身份用户组"]
  PS["权限集"] --> ASSIGN["访问授权"] --> PROVISION["权限集同步"]
  ACCOUNT --> WAIT["等待 180 秒"] --> ASSIGN
  GROUP --> ASSIGN
~~~

Core 和 Workloads 挂在企业组织根节点下，Production 挂在 Workloads 下。通过资源引用建立执行依赖。

首次访问授权建立账号、主体和权限集关系，随后显式同步权限集。修改策略后，应在云身份中心检查目标账号同步状态，需要时重新执行同步。

## 3. IaC 设计

### 3.1 资源清单

当前 `terraform.tfvars` 配置七种云资源，共 18 个云资源实例：

| Terraform 资源 | 数量 | 用途 |
| --- | --- | --- |
| `volcenginecc_organization_unit` | 3 | Core、Workloads、Production |
| `volcenginecc_organization_account` | 5 | 运维、安全、日志、生产、预发账号 |
| `volcenginecc_cloudidentity_user` | 2 | 平台管理员和审计员 |
| `volcenginecc_cloudidentity_group` | 2 | 管理员组和审计组，包含成员关系 |
| `volcenginecc_cloudidentity_permission_set` | 2 | 管理员和只读权限 |
| `volcenginecc_cloudidentity_permission_set_assignment` | 2 | 授权用户组访问指定账号 |
| `volcenginecc_cloudidentity_permission_set_provisioning` | 2 | 授权完成后向目标账号同步权限集 |

另有 1 个 `time_sleep` 等待辅助资源，当前全新部署合计为 19 个受管资源。等待是固定缓冲，不代表账号同步就绪检测。

授权实例键来自“权限集＋主体类型＋主体＋账号”；权限集同步按“权限集＋账号”去重。Apply 才生成的账号 ID 作为资源参数。

### 3.2 工程结构

~~~text
.
├── main.tf / variables.tf / locals.tf / outputs.tf
├── checks.tf
├── providers.tf / versions.tf / .terraform.lock.hcl
├── terraform.tfvars
└── modules/
    ├── organization/
    ├── identity/
    ├── permission-set/
    └── access/
~~~

根 `main.tf` 调用四个模块，模块内直接定义云资源。

`variables.tf` 校验字段格式、唯一性和取值范围；`checks.tf` 集中诊断账号 OU、用户密码、组成员及授权的跨输入引用。Terraform 的 `check` 失败只产生警告，强制阻断由变量校验及对应真实云资源的 `lifecycle.precondition` 执行，不增加辅助资源。

### 3.3 核心代码示例

~~~hcl
permission_set_assignments = [{
  permission_set_key = "ps_readonly"
  principal_type     = "Group"
  principal_key      = "grp_security_audit"
  target_account_key = "sjhTest04"
}]
~~~

这条配置允许审计组使用只读权限集访问生产账号；授权创建完成后，同一权限集将同步到目标账号。

## 4. 使用说明

本工程支持通过 InfraManager 在云上一键部署或下载模板在本地运行。推荐使用云上部署方式，无需自行准备 Terraform 运行环境，只需在平台填写参数即可完成资源创建和托管。

### 4.1 云上部署

#### 4.1.1 准备权限

使用组织管理员账号下有权限的身份，开通企业组织和云身份中心，并授予 CloudControl 权限及对应资源的操作权限。

#### 4.1.2 选择模板

上传至 [InfraManager 控制台](https://console.volcengine.com/iac)，入口使用仓库根目录。Terraform 最低为 1.5，`volcenginecc` 固定为 0.0.70。当前尚未验证目标 InfraManager 引擎的实际部署。

#### 4.1.3 创建资源栈

仅使用 `terraform.tfvars`。将根 OU ID 和账号名称占位值替换为实际值，通过敏感运行参数提供密码。

| 参数 | 用途 |
| --- | --- |
| `region` | Provider 地域 |
| `project` | 工程标签 |
| `environment` | 环境标签 |
| `root_parent_id` | 企业组织真实根 OU ID |
| `organization_units` | OU 定义 |
| `organization_accounts` | 新建账号定义及所属 OU |
| `cloud_identity_users` | 用户定义 |
| `cloud_identity_user_passwords` | 按用户 key 索引的敏感初始密码 |
| `cloud_identity_groups` | 用户组定义及成员用户 key |
| `permission_sets` | 权限集及策略 |
| `permission_set_assignments` | 主体、权限集、账号的授权关系 |

密码须为 8–32 字符，包含大写、小写、数字、特殊字符至少三类。不要提交密码。敏感标记只隐藏显示，不会加密 State。

#### 4.1.4 部署验证

| 输出 | 用途 |
| --- | --- |
| `organization_unit_ids` | OU ID |
| `organization_account_ids` | 账号 ID |
| `cloud_identity_user_ids` | 用户 ID |
| `cloud_identity_group_ids` | 用户组 ID |
| `permission_set_ids` | 权限集 ID |
| `permission_set_assignment_ids` | 授权 ID |
| `permission_set_provisioning_status` | 授权完成后的权限集同步状态 |

在控制台核对授权任务、权限集同步状态、资源关系和组成员，再使用实际员工登录验证目标账号与权限。

### 4.2 本地部署

#### 4.2.1 环境准备

安装 Terraform >=1.5，通过运行环境提供 `VOLCENGINE_ACCESS_KEY` 和 `VOLCENGINE_SECRET_KEY`。以 JSON 映射设置敏感变量 `TF_VAR_cloud_identity_user_passwords`。不要在 tfvars 中填写空密码映射，否则会覆盖环境变量。

#### 4.2.2 场景化部署示例

修改现有 `terraform.tfvars` 后运行：

~~~bash
terraform init
terraform validate
terraform plan
terraform apply
~~~

#### 4.2.3 部署预期结果

当前输入创建 18 个云资源及 1 个等待资源，共 19 个受管实例。所有账号创建完成并返回 ID 后等待 180 秒；等待、权限集和用户组创建完成后执行访问授权，全部授权完成后再按“权限集＋账号”去重同步。再次 Plan 应无非预期变更。

#### 4.2.4 部署后验证

通过 `terraform output` 获取资源、授权 ID 和权限集同步状态，核对控制台关系及员工登录效果。修改策略后重新确认同步状态。

#### 4.2.5 销毁资源

执行 `terraform destroy` 前检查 `terraform plan -destroy` 和账号删除前置条件。操作失败后检查残留资源；Terraform 不自动回滚已完成的变更。

## 5. 总结

四个模块直接管理七种云资源，共 18 个实例，另有 1 个账号同步等待资源。本次最终改造未执行 Terraform 测试、真实 Apply、员工登录或 Destroy 验收，验证由用户随后执行。
