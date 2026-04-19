---
name: github-issues-workflow
description: >
  Bootstrap an issue-driven development workflow for monorepo projects. Generates GitHub issue
  templates (general, bug, feature), a PR template, a label setup script, and four Claude Code
  slash commands that orchestrate the full lifecycle: create solution-agnostic issues, start work
  (branch, design doc, task file, implement, PR), review PRs with tech-specific checklists, and
  address feedback systematically. Issues track progress via .claude/issues/ folders with mandatory
  self-contained design.md and task.md files, archived to .claude/history/ after merge.
  Supports Rust, Python, Go, Java backends; React, Next.js, Svelte v5 frontends; iOS/Android
  mobile; and tooling crates. Use when setting up a new project's GitHub workflow, creating issue
  or PR templates, generating a label script, or bootstrapping Claude Code commands for
  issue-driven development.
---

# GitHub Issues Workflow

Bootstrap an issue-driven development workflow for monorepo projects.

## What This Skill Produces

1. **GitHub Label Setup Script** — `scripts/github/setup-labels.sh`
2. **Issue Templates** — `.github/ISSUE_TEMPLATE/{default,bug,feature}.md`
3. **PR Template** — `.github/PULL_REQUEST_TEMPLATE.md`
4. **Claude Code Commands** — `.claude/commands/{PREFIX}-{issue,start,review,address}.md`

## Workflow

### Phase 1: Gather Project Information

Ask the user for:

1. **GitHub repo** (e.g., `org/repo-name`)
2. **Project short name** — used as prefix for Claude commands (e.g., `frk` produces `/frk-issue`, `/frk-start`)
3. **Workspace areas** — which modules exist and their paths. Ask:
   - What backend tech? (Rust, Python, Go, Java, or none)
   - What frontend tech? (React, Next.js, Svelte v5, or none)
   - Mobile apps? (iOS, Android, or none)
   - Tooling crates/packages? (Rust crates, Python packages, Go modules, etc.)
   - Infrastructure/DevOps? (Docker, CI/CD, etc.)
4. **Architecture style** — if applicable (hexagonal, layered, clean, microservices, monolith, etc.)
5. **Branching strategy** — main branch name (`main` or `master`), branch naming convention

Consult `references/tech-stacks.md` for tech-specific check commands, package managers, and workspace patterns.

### Phase 2: Generate Labels Script

Generate `scripts/github/setup-labels.sh` using the script template in `scripts/generate-labels.sh`.

Customize area labels based on the project's actual workspace areas. Keep type, priority, and status labels standard.

### Phase 3: Generate Issue Templates

Copy and customize templates from `assets/issue-templates/`:

- `default.md` — General issue (solution-agnostic, focus on WHAT/WHY not HOW)
- `bug.md` — Bug report with environment details
- `feature.md` — Feature request with user story format

Replace area checkboxes with the project's actual workspace areas.

### Phase 4: Generate PR Template

Copy and customize `assets/pull-request-template.md`. Replace:
- Area checkboxes with project's workspace areas
- Testing checklist with tech-appropriate check commands (from `references/tech-stacks.md`)

### Phase 5: Generate Claude Code Commands

Generate four slash commands in `.claude/commands/` using the project short name as prefix. Consult `references/commands-guide.md` for the full workflow specification and customize per-project.

| Command | File | Purpose |
|---------|------|---------|
| `/{PREFIX}-issue` | `{PREFIX}-issue.md` | Create GitHub issue with proper labels and templates |
| `/{PREFIX}-start` | `{PREFIX}-start.md` | Full issue-to-PR workflow: branch, design doc, task file, implement, PR |
| `/{PREFIX}-review` | `{PREFIX}-review.md` | Structured PR review with tech-specific checklist |
| `/{PREFIX}-address` | `{PREFIX}-address.md` | Address PR/issue feedback systematically |

Key customizations per project:
- Repo name in all `gh` commands
- Workspace areas table with paths and check commands
- Tech-specific quality checks (from `references/tech-stacks.md`)
- Architecture-specific review criteria

### Phase 6: Run Label Setup

Ask if the user wants to run the label setup script now:
```bash
bash scripts/github/setup-labels.sh
```

### Phase 7: Commit

Stage and commit all generated files:
```bash
git add scripts/github/ .github/ .claude/commands/
git commit -m "chore: add GitHub workflow infrastructure"
```

## Key Design Principles

- **Solution-agnostic issues** — Issues describe WHAT and WHY, never HOW. No file paths or code specifics in issues.
- **Self-contained design docs** — `.claude/issues/issue-N/design.md` copies all specs verbatim; never references external files by path.
- **Task tracking** — `.claude/issues/issue-N/task.md` with checkbox tasks checked off during implementation.
- **Issue lifecycle** — Active work in `.claude/issues/`, archived to `.claude/history/` after PR merge.
- **Conventional commits** — `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`
- **No AI attribution** — Never add `Co-Authored-By: Claude` or similar to commits.
