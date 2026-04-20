# Terraform / OpenTofu conventions

Terraform (HashiCorp, BSL-licensed since v1.6) and OpenTofu (community
fork, MPL) share configuration syntax and nearly all commands. This file
covers both. Swap the binary name (`terraform` ↔ `tofu`) — everything
else is the same unless called out.

New projects with licensing concerns or a preference for open governance
default to **OpenTofu**. Existing HashiCorp-aligned shops stay on
Terraform. Don't silently migrate one to the other without asking.

## Detection

| Signal                          | Meaning                                        |
| ------------------------------- | ---------------------------------------------- |
| `*.tf` files                    | Terraform / OpenTofu config                    |
| `*.tfvars`                      | Variable values (often per-env)                |
| `.terraform.lock.hcl`           | Provider version lockfile (commit this)        |
| `.terraform/` directory         | Local provider/modules cache (gitignore)       |
| `*.tfstate` / `*.tfstate.backup`| Local state (gitignore — should be remote)     |
| `versions.tf`                   | Required terraform/tofu + provider versions    |
| `providers.tf`                  | Provider config                                |
| `terragrunt.hcl`                | Terragrunt wrapper on top                      |
| `.opentofu-version` / `.terraform-version` | Pinned tool version (tenv, tfenv)   |

## Tooling

Use the Terraform or OpenTofu binary, plus a small stable ecosystem:

| Concern             | Terraform                                 | OpenTofu                              |
| ------------------- | ----------------------------------------- | ------------------------------------- |
| Init                | `terraform init -upgrade`                 | `tofu init -upgrade`                  |
| Format (recursive)  | `terraform fmt -recursive`                | `tofu fmt -recursive`                 |
| Validate            | `terraform validate`                      | `tofu validate`                       |
| Plan (to file)      | `terraform plan -out=plan.tfplan`         | `tofu plan -out=plan.tfplan`          |
| Apply (from file)   | `terraform apply plan.tfplan`             | `tofu apply plan.tfplan`              |
| Destroy             | `terraform destroy`                       | `tofu destroy`                        |
| Show / output       | `terraform show` / `terraform output`     | `tofu show` / `tofu output`           |

Additional tools that belong in the pre-commit pipeline:

- **`tflint`** — static analysis for provider-specific misuse (cloud
  resource naming, deprecated args). Configure rules per provider in
  `.tflint.hcl`.
- **`tfsec`** or **`checkov`** — security scanning. Both detect
  misconfigurations (public S3 buckets, unencrypted volumes, etc.). Pick
  one; don't run both in CI as they overlap noisily.
- **`terraform-docs`** — generate module README tables from
  variables/outputs. Commit the output.
- **`tenv`** (modern) or **`tfenv` / `tofuenv`** — per-project binary
  version management. Pair with `.terraform-version` /
  `.opentofu-version`.

For testing modules: **`terratest`** (Go-based integration tests) is the
baseline; OpenTofu's native `tofu test` (HCL-based) is maturing and fine
for simple cases.

## Idiomatic rules to port / bootstrap

- **Pre-commit pipeline**: `tofu fmt -recursive && tofu validate && tflint && tfsec .` (or Checkov). Never commit without a clean `fmt` pass — it's trivially automatable.
- **Plan-then-apply discipline**: `tofu plan -out=plan.tfplan` then `tofu apply plan.tfplan`. Never `apply` without reviewing the plan file. CI applies must replay the exact reviewed plan — no implicit re-plan during apply.
- **State is remote, not local.** `backend "s3"` / `backend "gcs"` / `backend "azurerm"` / Terraform Cloud / Scalr. Local state is a single laptop's disk — unacceptable for anything beyond experimentation.
- **Lock remote state** (DynamoDB table for S3, native locking for newer backends). Concurrent applies corrupt state otherwise.
- **Gitignore** `.terraform/`, `*.tfstate`, `*.tfstate.backup`, `crash.log`, `override.tf*`, `*.tfplan`. Never commit any of these.
- **Commit `.terraform.lock.hcl`.** It pins provider hashes for reproducible installs across machines.
- **Pin everything**. `required_version = "~> 1.9"` for the tool, `version = "~> 5.0"` (or more constrained) for each provider. No unpinned providers in shared modules.
- **Separate state per environment**, not per workspace. Workspaces mix production with dev under one backend — dangerous. Use distinct backend configs per env (`environments/prod/main.tf` + `environments/dev/main.tf`) or use Terragrunt.
- **Module layout**: `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, `README.md` (generated via terraform-docs). Keep modules small and composable.
- **Every variable has a `type`** — no bare `variable "x" {}` without a type signature. Primitive types where possible; `object({...})` for structured input.
- **Mark secrets `sensitive = true`** on variables and outputs. Don't try to hide them with naming conventions.
- **Prefer `for_each` over `count`** for resources that can be identified by a stable key. `count` uses positional state addresses — renames become destroy+create.
- **`moved { from = ... to = ... }` blocks** when refactoring resource addresses across modules or renames. Never orphan resources in state by doing a "rewrite then manual state mv" dance.
- **Data sources, not hardcoded IDs.** `data "aws_vpc" "default"` beats an AMI or VPC ID pasted into the config.
- **No inline secrets.** Use provider-native secret managers (AWS Secrets Manager, GCP Secret Manager, Vault). Never `default = "AKIA..."` in a variable.

## Module structure

A reusable module's shape:

```
modules/
  my-module/
    README.md           # generated by terraform-docs
    main.tf             # resources
    variables.tf        # typed inputs with descriptions
    outputs.tf          # typed outputs, sensitive where needed
    versions.tf         # required_version + required_providers
    examples/
      basic/
        main.tf         # how to consume the module
```

Consumer:

```hcl
module "vpc" {
  source  = "./modules/vpc"
  name    = "production"
  cidr    = "10.0.0.0/16"
}
```

Public registry modules pin via `source = "..."` + `version = "~> x.y"`.
Private git modules pin via ref: `source = "git::ssh://git@github.com/org/mod.git?ref=v1.2.3"`.

## Environments

Two patterns, both valid:

- **Terragrunt** — one `terragrunt.hcl` per environment pulls in a shared
  module. DRY by design. The de facto choice for large multi-env setups.
- **Per-env directories** — `environments/dev/main.tf` etc., each with its
  own `backend` config, wiring the same shared modules with different
  inputs. Simpler mental model; more copy-paste.

Pick one and stick with it. Mixing both in the same repo is painful.

## Testing

- **`tofu validate`** + **`tflint`** in CI for every PR.
- **`tfsec` / `checkov`** as a non-blocking advisory unless your org
  mandates it.
- **Plan review** is part of PR review: CI generates `plan.tfplan`, posts
  the summary as a PR comment, blocks on manual approval before apply.
- **`terratest`** for module integration tests that actually stand up
  real resources (in a test account/project) and assert on them. Tag
  slow/expensive tests with a build tag so they don't run on every PR.

## CI/CD

- **Branch protection**: no direct push to main. PR + plan review + apply
  happens only from main on merge.
- **Apply from CI, not laptops.** Production apply from a developer
  machine is a red flag — use Atlantis, Terraform Cloud, Spacelift, or
  similar, or a simple GitHub Actions workflow with locked apply
  permissions.
- **Artifacts**: save `plan.tfplan` in CI so the apply job uses the
  reviewed plan verbatim. Re-planning at apply time defeats the review.

## Polyglot path-scoping

```yaml
---
paths:
  - "**/*.tf"
  - "**/*.tfvars"
  - "**/*.hcl"
  - "**/.terraform.lock.hcl"
  - "**/.terraform-version"
  - "**/.opentofu-version"
  - "infra/**"
  - "terraform/**"
  - "tofu/**"
  - "modules/**"
  - "environments/**"
---
```

## Example `.claude/rules/terraform.md` skeleton

```markdown
# Terraform / OpenTofu

Applies to: infrastructure definitions under `infra/`.

Tool: OpenTofu (`tofu`). Swap for `terraform` if this repo is pinned to HashiCorp.

## Pre-commit pipeline

    tofu fmt -recursive
    tofu validate
    tflint
    tfsec .

## Plan / apply discipline

    tofu plan -out=plan.tfplan
    tofu apply plan.tfplan

Never apply without the plan file. CI re-uses the reviewed plan verbatim.

## State

- Remote backend only (S3 + DynamoDB lock).
- Separate state per environment, not via workspaces.
- Gitignore: `.terraform/`, `*.tfstate*`, `*.tfplan`, `crash.log`, `override.tf*`.
- Commit: `.terraform.lock.hcl`.

## Versions

- `required_version = "~> 1.9"`.
- All providers pinned: `version = "~> 5.0"` (or tighter).

## Module conventions

- Every variable has a `type` and a `description`.
- `sensitive = true` on every secret var/output.
- Prefer `for_each` over `count`.
- Use `moved {}` blocks when refactoring addresses.
- No inline secrets — pull from Secrets Manager / Vault via data sources.

## Environments

We use Terragrunt — one `terragrunt.hcl` per env under `environments/`.
The shared module code lives under `modules/`.
```
