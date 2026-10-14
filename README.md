# Volcengine Multi-account Identity and Access Management

English | [简体中文](README.zh-CN.md)

This template provides centralized identity and access management across enterprise accounts. Four modules configure organization units, member accounts, Cloud Identity users and groups, permission sets and access assignments. The repository root is the only Terraform entry point. One State manages resources created by this template, while existing member accounts can be used as authorization targets.

## 1. Business Background

- Organize member accounts for operations, security, logging, production and staging, with clear responsibilities and organization hierarchy.
- Manage employees and groups centrally in Cloud Identity, reducing identity and permission maintenance in individual accounts.
- Control account access through administrator, read-only and other permission sets, with support for both newly-created and existing member accounts.

## 2. Solution Overview

`organization` creates OUs and new accounts; `identity` creates users and groups; `permission-set` defines permissions; `access` merges newly-created account outputs with existing account IDs, waits 180 seconds after account creation, creates assignments, then provisions permission sets. Existing accounts are authorization targets only; their OU, tags and lifecycle are not managed.

~~~mermaid
flowchart LR
    classDef main fill:#EAF4FF,stroke:#5B8FF9,color:#0D47A1;
    classDef tcc fill:#DFF2FF,stroke:#409EFF,color:#0D47A1;
    classDef note fill:#FFFDE7,stroke:#FBC02D,color:#5D4037;

    Vars[/"terraform.tfvars<br/>OUs / new and existing accounts / users / groups<br/>Permission-set / assignment declarations"/]:::tcc
    EXISTING[/"existing_organization_account_ids<br/>Member account IDs already in the organization<br/>References only; no account creation"/]:::tcc

    subgraph Org["Organization layer"]
        direction TB
        OU["organization_unit<br/>Organization units"]:::main
        ACC["organization_account<br/>New member accounts"]:::main
        OU --> ACC
    end

    subgraph Identity["Cloud Identity layer"]
        direction TB
        USER["cloudidentity_user<br/>Cloud Identity users"]:::main
        GRP["cloudidentity_group<br/>Cloud Identity groups"]:::main
        PS["cloudidentity_permission_set<br/>Access permission sets"]:::main
        USER -.->|Membership| GRP
    end

    subgraph Assign["Assignment layer"]
        direction TB
        WAIT["time_sleep<br/>Wait 180 seconds after account IDs are available"]:::tcc
        ASN["permission_set_assignment<br/>Access assignments"]:::main
        PROV["permission_set_provisioning<br/>Permission-set provisioning"]:::main
        WAIT --> ASN --> PROV
    end

    Vars --> Org
    Vars --> Identity
    Vars --> Assign
    Vars --> EXISTING
    GRP --> ASN
    USER --> ASN
    PS --> ASN
    ACC --> WAIT
    EXISTING --> WAIT

    NoteOU["OU notes<br/>- Core and Workloads are children of root_parent_id<br/>- Production is a child of Workloads<br/>- The current template uses this fixed topology"]:::note
    NoteACC["Member account notes<br/>- New names are unique and must not match existing keys<br/>- Empty verification_relation_id becomes null and is omitted<br/>- Merge common_tags and the AccountType tag"]:::note
    NotePS["Permission-set notes<br/>- Supports mixed System + Inline policies<br/>- session_duration: 3600–43200 seconds"]:::note
    NoteASN["Assignment notes<br/>- principal: User or Group<br/>- depends_on ensures assignment before provisioning<br/>- Deduplicate by permission set and target account"]:::note

    OU -.-> NoteOU
    ACC -.-> NoteACC
    PS -.-> NotePS
    PROV -.-> NoteASN
~~~

Core and Workloads are children of the organization root; Production is a child of Workloads. Resource references establish dependencies.

The initial assignment establishes the account, principal and permission-set relationship, then explicit provisioning synchronizes the permission set. After policy changes, check synchronization and reprovision when required.

**Deployment parallelism must be set to 1.** Member-account creation does not support parallelism greater than 1. The account list in the template does not automatically serialize creation. Both cloud stacks and local runs must follow this requirement; see Section 4 for the settings.

**This template does not support complete resource deletion through `terraform destroy`.** Deleting or closing a member account requires interactive console steps, including identity verification, that Terraform cannot perform. See [Destroy Resources](#425-destroy-resources) for cleanup instructions.

## 3. IaC Design

### 3.1 Resource Inventory

After completing the current `terraform.tfvars` example inputs, the configuration is expected to create seven cloud resource types and 22 cloud instances, and reference five existing member accounts. Counts change with the account, identity and assignment configuration. The example counts are:

| Terraform Resource | Purpose |
| --- | --- |
| `volcenginecc_organization_unit` × 3 | Core, Workloads and Production organization units |
| `volcenginecc_organization_account` × 5 | New Operation, Security, Logging, Production and Staging accounts |
| `volcenginecc_cloudidentity_user` × 2 | Platform administrator and auditor |
| `volcenginecc_cloudidentity_group` × 2 | Administrator and audit groups with membership |
| `volcenginecc_cloudidentity_permission_set` × 2 | Administrator and read-only permissions |
| `volcenginecc_cloudidentity_permission_set_assignment` × 4 | Grant groups access to new or existing accounts |
| `volcenginecc_cloudidentity_permission_set_provisioning` × 4 | Synchronize permission sets after assignment |
| `time_sleep` × 1 | Wait 180 seconds when assignments exist; omitted when there are no assignments; creates no cloud resources |

The example totals 23 managed instances. Existing accounts are references, not managed account resources; their accounts, OUs, tags and lifecycle are not managed. The fixed buffer does not verify account synchronization readiness. Assignment count follows `permission_set_assignments`; provisioning count follows its distinct permission-set and target-account pairs.

Assignment instance keys combine permission set, principal type, principal and account. Provisioning is deduplicated by permission set and account. New account IDs come from the organization module; existing account IDs come from `existing_organization_account_ids`; access receives the merged map.

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

New account names must be unique within `organization_accounts` and must not appear in `existing_organization_account_ids`. A conflict fails the Plan before execution.

### 3.3 Key Code Examples

~~~hcl
permission_set_assignments = [{
  permission_set_key = "ps_readonly"
  principal_type     = "Group"
  principal_key      = "grp_security_audit"
  target_account_key = "existing-production"
}]
~~~

This grants the audit group access to the production account using the read-only permission set. After assignment, the permission set is synchronized to the target account.

## 4. Usage

This project supports cloud deployment through InfraManager or local deployment using the downloaded template. Cloud deployment is recommended: you do not need to prepare a Terraform runtime, and you can create and manage resources by entering parameters in the platform.

### 4.1 Cloud Deployment

InfraManager is Volcengine's managed Terraform workspace. For more information, see the [InfraManager product introduction](https://docs.volcengine.com/docs/infrastructure-management/product-introduction?lang=zh).

#### 4.1.1 Prepare Permissions

Use an authorized identity in the organization administrator account. Enable Organization and Cloud Identity in the console and obtain the organization root OU ID. The execution identity needs CloudControl resource-operation permissions and the corresponding permissions for organization OUs, member accounts, Cloud Identity users, groups, permission sets, assignments and provisioning. Run through an IAM identity or delegated role, with permissions scoped to the resources being managed.

#### 4.1.2 Select the Template

Upload the project as a custom template to the [InfraManager console](https://console.volcengine.com/iac), using the repository root as the entry point. Include the root Terraform files, `terraform.tfvars`, `.terraform.lock.hcl` and the complete `modules/` directory. Select Terraform 1.5.7. The template pins `volcenginecc` to 0.0.70 and `time` to 0.14.2; the runtime must support both providers.

#### 4.1.3 Create a Stack

When creating the stack, fill in the template inputs and set **execution parallelism to 1**. For API-based creation, the execution parameter is `Parallelism = 1`; do not use the default parallelism. See [stack creation execution parameters](https://docs.volcengine.com/docs/infrastructure-management/CreateStack-Createaresourcestack?lang=zh). This is a runtime setting, not a business variable in `terraform.tfvars`. If the current entry point cannot set parallelism to 1, confirm the platform runtime settings first, or use the local deployment procedure below.

`terraform.tfvars` is the delivered example, while `variables.tf` defines types, defaults and validation. Before deployment, fill in the currently empty `root_parent_id`, existing account IDs and initial user passwords, and replace example names and email addresses with the customer's configuration. Existing accounts must already belong to the current organization, and their IDs must be distinct numeric strings. Supply passwords through platform sensitive runtime parameters that override the empty example values; do not include passwords in the deliverable.

| Input | Purpose |
| --- | --- |
| `region` | Provider region |
| `project` | Project tag |
| `environment` | Environment tag |
| `root_parent_id` | Actual organization root OU ID |
| `organization_units` | OU definitions |
| `organization_accounts` | New account definitions and target OUs |
| `existing_organization_account_ids` | Existing account-name to account-ID map, used only for authorization |
| `cloud_identity_users` | User definitions |
| `cloud_identity_user_passwords` | Sensitive initial passwords indexed by user key |
| `cloud_identity_groups` | Group definitions and member user keys |
| `permission_sets` | Permission sets and policies |
| `permission_set_assignments` | Principal, permission-set and account relationships |

Passwords must be 8–32 characters with at least three of uppercase, lowercase, digits and special characters. Do not commit passwords. Sensitive marking hides display but does not encrypt State.

For new accounts only, set `existing_organization_account_ids` to `{}` and remove assignments to those existing accounts. For existing accounts only, set `organization_accounts` to `[]`; also set `organization_units` to `[]` if no new OUs are needed. For a mixed configuration, fill in both account inputs and use `target_account_key` to select authorization targets. These are initial-deployment scenarios. Removing list entries from an existing deployment creates deletion plans; review changes first and do not use this to bypass interactive account deletion.

Create and review the execution plan, then deploy after confirming the resource scope and authorization targets. The template does not automatically enforce parallelism of 1 or prohibit resource destruction. Operators must follow these runtime requirements.

#### 4.1.4 Verify the Deployment

On the stack details page, confirm successful deployment and review the resource list and outputs below. Use actual IDs from stack outputs for verification; local Terraform State is not required.

| Output | Purpose |
| --- | --- |
| `organization_unit_ids` | OU IDs |
| `organization_account_ids` | Account IDs |
| `cloud_identity_user_ids` | User IDs |
| `cloud_identity_group_ids` | Group IDs |
| `permission_set_ids` | Permission-set IDs |
| `permission_set_assignment_ids` | Assignment IDs |
| `permission_set_provisioning_status` | Permission-set synchronization status after assignment |

| Check | Console entry point and action | Expected result and troubleshooting |
| --- | --- | --- |
| OU and account placement | Use output IDs to inspect OUs and member accounts in the Organization console | Core and Workloads are children of the root, and Production is a child of Workloads; new accounts belong to their specified OUs. Check the root OU ID and `org_unit_key` if incorrect |
| Users and group membership | Inspect users, groups and member lists in Cloud Identity | The administrator group contains the platform administrator; the audit group contains the auditor. Check user keys, member keys and password inputs if incorrect |
| Permissions and provisioning | Inspect permission-set policies, account assignments and provisioning tasks in Cloud Identity | The administrator set contains `AdministratorAccess`, and the read-only set contains `ReadOnlyAccess`; target accounts are correct, and assignment and provisioning tasks have succeeded. Check organization membership, execution permissions and failed-task reasons if incorrect |
| Employee login | Have each user type sign in through the customer's Cloud Identity user portal and select assigned accounts and permission sets | The example administrator can access new and existing operations accounts; the auditor can access new and existing production accounts. This template must not grant access to unassigned accounts. Check additional grants, group membership and provisioning status, then sign in again using separate sessions |

Successful resource creation and non-empty outputs do not replace employee-login and effective-permission checks. After checking resources, verify administrator and read-only permission boundaries against the customer's intended business operations. Recheck provisioning after policy changes. Cloud cleanup must also follow the [manual cleanup procedure](#425-destroy-resources); do not replace interactive member-account deletion with complete stack destruction.

### 4.2 Local Deployment

You can also download and run the template locally by following the steps below.

#### 4.2.1 Prepare the Environment

Install Terraform 1.5.7, confirm that the pinned providers can be downloaded, and complete the same service activation, root OU ID and permission preparation as for cloud deployment. Check member-account quotas and existing-account organization membership before deployment. Provide credentials through the runtime environment; do not put actual AK/SK values in Terraform files or the deliverable:

~~~bash
export VOLCENGINE_ACCESS_KEY="<YOUR_ACCESS_KEY>"
export VOLCENGINE_SECRET_KEY="<YOUR_SECRET_KEY>"
~~~

Replace the example root OU ID, existing account IDs, resource names and email addresses with the customer's values. See [Create a Stack](#413-create-a-stack) for input descriptions. Do not deploy while account IDs remain empty.

Provide initial user passwords through the `TF_VAR_cloud_identity_user_passwords` JSON map. First remove or comment out the entire `cloud_identity_user_passwords` assignment block in `terraform.tfvars`; otherwise the empty example values override the environment variable. Then set the actual passwords in the runtime environment:

~~~bash
export TF_VAR_cloud_identity_user_passwords='{"platform_admin":"<ADMIN_INITIAL_PASSWORD>","auditor":"<AUDITOR_INITIAL_PASSWORD>"}'
~~~

Replace the placeholders with actual passwords that satisfy the password rules. Do not write passwords back into the delivered example or commit them. State may also contain passwords and must be stored securely with restricted access.

#### 4.2.2 Scenario-based Deployment Examples

Choose new, existing or mixed accounts and update the inputs according to [Create a Stack](#413-create-a-stack), then run the commands below. **Account creation does not support parallelism greater than 1, so both Plan and Apply must explicitly use `-parallelism=1`.** Keep the same execution settings even for existing-only deployments to avoid missing this requirement when new accounts are added later.

~~~bash
terraform init
terraform fmt -check -recursive
terraform validate
terraform plan -parallelism=1
terraform apply -parallelism=1
~~~

Review Plan first and confirm that it contains no unexpected deletions or account replacements before running Apply. Parallelism of 1 limits simultaneous operations; it does not guarantee creation in list order.

#### 4.2.3 Expected Deployment Results

After completing the current example inputs, deployment is expected to create 22 cloud resources and one wait helper, totaling 23 managed instances, and reference five existing accounts. New accounts finish creation and return IDs before the 180-second wait starts. Assignments then target the configured new and existing accounts, and provisioning is deduplicated by permission set and account. Only some existing accounts have assignments; supplying an account ID alone does not grant permissions.

View outputs with the command below. Output names and purposes are listed under [Verify the Deployment](#414-verify-the-deployment):

~~~bash
terraform output
~~~

Run `terraform plan -parallelism=1` again with the same inputs; expect no unexpected changes. If deletions or replacements appear, compare inputs with console resources before running Apply.

#### 4.2.4 Post-deployment Verification

First run `terraform output` to obtain actual resource, account and assignment IDs from the local deployment. Then complete the console relationship, group membership, permission provisioning and employee-portal checks under [Verify the Deployment](#414-verify-the-deployment). Use the relevant employee identity rather than the deployment administrator for portal checks. Use separate sessions for the administrator and auditor to avoid account-switching effects. Resolve failed provisioning tasks first. After policy changes, recheck and reprovision when required; Apply success alone does not prove that target-account permissions have been updated.

#### 4.2.5 Destroy Resources

**Do not run `terraform destroy` or trigger complete resource destruction for this template through InfraManager.** Deleting or closing member accounts created by this template requires interactive console steps, including security-phone and identity verification, that Terraform cannot automate. Removing a member account from the organization is not account closure; disappearance from the organization list does not prove permanent deletion.

When cleanup is required, perform the following steps manually within the customer's authorized scope:

1. Compare template outputs with actual resources and identify only resources created by this template that are no longer needed. Existing accounts are outside the account-deletion scope. Address business data, cloud resources and billing prerequisites first.
2. In Cloud Identity, revoke account assignments created by this template and follow console instructions to handle provisioning relationships. Remove permission sets, groups and users created by this template only after confirming that no other workloads use them.
3. Locate the member accounts created by this template in Organization member management. Configure a security phone, enable login and complete verification as needed. See [Set an account security phone](https://docs.volcengine.com/docs/EnterpriseOrganization/Setaccountsecurityphone?lang=zh).
4. Using an authorized identity for the account being deleted, open Account Management's Security Settings and follow the [account closure procedure](https://docs.volcengine.com/docs/account_related/Accountcancellation?lang=zh) to complete identity verification, resource and billing checks, and closure confirmation. Use the final account status shown in the console as the outcome.
5. After resolving member accounts and their relationships, verify that OUs created by this template contain no members or child OUs, then remove unused OUs from the bottom up. Do not delete existing customer accounts or the organization root.

Manual cleanup creates differences between cloud resources and Terraform State or stack records. Retain cleanup results and have operations staff reconcile management records after verification. Do not run Apply again without review, as it can recreate cleaned-up resources. The template code does not automatically block destruction; this restriction must be enforced operationally.

## 5. Summary

This template centralizes permissions for newly-created and existing member accounts through a unified organization, identity, permission-set and assignment configuration. Customers can adjust accounts, groups and assignments for their business scale, then verify employee access and permission boundaries after deployment.

Execution parallelism must remain 1. Member-account cleanup requires interactive console steps and cannot be completed through `terraform destroy`. This guide describes procedures and expected results derived from current code; historical deployment or test records are not presented as proof that this version has passed live acceptance.
