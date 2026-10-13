# Volcengine Multi-account Identity and Access Management

English | [简体中文](README.zh-CN.md)

The repository root is the only Terraform entry point. Four modules create the organization, identities, permission sets and access in one Apply and one State.

## 1. Business Background

Users belong to groups. Permission sets define policies. An assignment grants a user or group access to an account; after assignment, provisioning synchronizes the permission set to the target account.

## 2. Solution Overview

`organization` creates OUs and accounts; `identity` creates users and groups; `permission-set` defines permissions; `access` waits 180 seconds after account creation, creates assignments, then provisions permission sets.

~~~mermaid
flowchart LR
  OU["Organization units"] --> ACCOUNT["Organization accounts"]
  USER["Cloud Identity users"] --> GROUP["Cloud Identity groups"]
  PS["Permission sets"] --> ASSIGN["Permission-set assignments"] --> PROVISION["Permission-set provisioning"]
  ACCOUNT --> WAIT["Wait 180 seconds"] --> ASSIGN
  GROUP --> ASSIGN
~~~

Core and Workloads are children of the organization root; Production is a child of Workloads. Resource references establish dependencies.

The initial assignment establishes the account, principal and permission-set relationship, then explicit provisioning synchronizes the permission set. After policy changes, check synchronization and reprovision when required.

## 3. IaC Design

### 3.1 Resource Inventory

The current `terraform.tfvars` defines seven cloud resource types and 18 cloud instances:

| Terraform Resource | Count | Purpose |
| --- | --- | --- |
| `volcenginecc_organization_unit` | 3 | Core, Workloads and Production |
| `volcenginecc_organization_account` | 5 | Operation, Security, Logging, Production and Staging |
| `volcenginecc_cloudidentity_user` | 2 | Platform administrator and auditor |
| `volcenginecc_cloudidentity_group` | 2 | Administrator and audit groups with membership |
| `volcenginecc_cloudidentity_permission_set` | 2 | Administrator and read-only permissions |
| `volcenginecc_cloudidentity_permission_set_assignment` | 2 | Grant the groups access to selected accounts |
| `volcenginecc_cloudidentity_permission_set_provisioning` | 2 | Synchronize permission sets after assignment |

One additional `time_sleep` helper waits 180 seconds, bringing a fresh deployment to 19 managed resources. The fixed buffer does not verify account synchronization readiness.

Assignment instance keys combine permission set, principal type, principal and account. Provisioning is deduplicated by permission set and account. Account IDs generated during Apply are resource arguments.

### 3.2 Project Structure

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

Root `main.tf` calls these four modules. Each module defines its cloud resources directly.

`variables.tf` validates formats, uniqueness and ranges. `checks.tf` diagnoses cross-input references for account OUs, user passwords, group members and assignments. Terraform `check` failures are warnings; variable validation and the corresponding cloud resource's `lifecycle.precondition` reject invalid inputs without adding helper resources.

### 3.3 Key Code Examples

~~~hcl
permission_set_assignments = [{
  permission_set_key = "ps_readonly"
  principal_type     = "Group"
  principal_key      = "grp_security_audit"
  target_account_key = "sjhTest04"
}]
~~~

This grants the audit group access to the production account using the read-only permission set. After assignment, the permission set is synchronized to the target account.

## 4. Usage

This project supports cloud deployment through InfraManager or local deployment using the downloaded template. Cloud deployment is recommended: you do not need to prepare a Terraform runtime, and you can create and manage resources by entering parameters in the platform.

### 4.1 Cloud Deployment

#### 4.1.1 Prepare Permissions

Use an authorized identity in the organization administrator account. Enable Organization and Cloud Identity, and grant CloudControl permissions plus the corresponding resource permissions.

#### 4.1.2 Select the Template

Upload the project to the [InfraManager console](https://console.volcengine.com/iac) with the repository root as entry point. Terraform must be >=1.5; `volcenginecc` is pinned to 0.0.70. Actual deployment on the target InfraManager engine has not been verified.

#### 4.1.3 Create a Stack

Use the single `terraform.tfvars`. Replace the root OU ID and account-name placeholders with actual values, and supply passwords through sensitive runtime parameters.

| Input | Purpose |
| --- | --- |
| `region` | Provider region |
| `project` | Project tag |
| `environment` | Environment tag |
| `root_parent_id` | Actual organization root OU ID |
| `organization_units` | OU definitions |
| `organization_accounts` | New account definitions and target OUs |
| `cloud_identity_users` | User definitions |
| `cloud_identity_user_passwords` | Sensitive initial passwords indexed by user key |
| `cloud_identity_groups` | Group definitions and member user keys |
| `permission_sets` | Permission sets and policies |
| `permission_set_assignments` | Principal, permission-set and account relationships |

Passwords must be 8–32 characters with at least three of uppercase, lowercase, digits and special characters. Do not commit passwords. Sensitive marking hides display but does not encrypt State.

#### 4.1.4 Verify the Deployment

| Output | Purpose |
| --- | --- |
| `organization_unit_ids` | OU IDs |
| `organization_account_ids` | Account IDs |
| `cloud_identity_user_ids` | User IDs |
| `cloud_identity_group_ids` | Group IDs |
| `permission_set_ids` | Permission-set IDs |
| `permission_set_assignment_ids` | Assignment IDs |
| `permission_set_provisioning_status` | Permission-set synchronization status after assignment |

Check assignment tasks, provisioning status, relationships and group members in the console, then log in as an employee to verify intended accounts and permissions.

### 4.2 Local Deployment

#### 4.2.1 Prepare the Environment

Install Terraform >=1.5. Provide `VOLCENGINE_ACCESS_KEY` and `VOLCENGINE_SECRET_KEY` through the runtime environment. Provide `TF_VAR_cloud_identity_user_passwords` as a JSON map. Do not put an empty password map in tfvars: it would override the environment variable.

#### 4.2.2 Scenario-based Deployment Examples

Edit the existing `terraform.tfvars`, then run:

~~~bash
terraform init
terraform validate
terraform plan
terraform apply
~~~

#### 4.2.3 Expected Deployment Results

Current inputs create 18 cloud resources and one wait helper, totaling 19 managed instances. All accounts must finish creation and return IDs before the 180-second wait starts; assignments run after the wait, permission sets and groups are ready, then provisioning is deduplicated by permission set and account. A subsequent Plan should have no unexpected changes.

#### 4.2.4 Post-deployment Verification

Read resource IDs, assignment IDs and provisioning statuses with `terraform output`, then perform the console and employee-login checks above. After policy changes, verify synchronization again.

#### 4.2.5 Destroy Resources

Review `terraform plan -destroy` and account-deletion prerequisites before running `terraform destroy`. After failures, check residual resources; Terraform does not automatically roll back completed changes.

## 5. Summary

Four modules directly manage seven cloud resource types and 18 instances, plus one account-propagation wait resource. This final revision has not undergone Terraform tests, live Apply, employee-login checks or Destroy acceptance; validation will be executed separately.
