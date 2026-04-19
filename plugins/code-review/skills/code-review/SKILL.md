---
name: code-review
description: >
  Generate a project-specific clean code review command for any repo. Auto-detects tech stacks
  (Rust, Python, Go, Java, TypeScript, React, Next.js, Svelte 5, Swift, Kotlin) and produces a
  /{PREFIX}-code-review Claude Code command tailored to the repo's modules, architecture, and
  languages. The generated command performs deep code quality analysis across 7 clean code
  categories: SRP, DRY, dead code, stubs, complexity, coupling, and naming. Use when setting up
  code review tooling for a project, bootstrapping a code review command, or creating a customized
  clean code analysis workflow. Also use when the user mentions wanting code review, clean code
  analysis, or quality checks for their codebase.
---

# Code Review Command Generator

Generate a project-specific `/{PREFIX}-code-review` Claude Code command that performs deep clean code analysis tailored to the repo's tech stacks, module structure, and architecture.

## What This Skill Produces

A single Claude Code command: `.claude/commands/{PREFIX}-code-review.md`

The generated command includes:
- Scope mapping (keyword → directory paths)
- All 7 clean code categories with tech-appropriate examples and thresholds
- Stack-specific quality checks for the project's languages/frameworks only
- Per-category structured report tables
- Post-report triage with issue command integration (when available)
- Quality check commands per workspace area

## Workflow

### Phase 1: Auto-Detect Project Structure

Scan the repo root for tech markers:

| Marker | Tech |
|--------|------|
| `Cargo.toml` | Rust |
| `pyproject.toml`, `setup.py`, `requirements.txt` | Python |
| `go.mod` | Go |
| `build.gradle`, `build.gradle.kts`, `pom.xml` | Java/Kotlin |
| `package.json` (check `dependencies` for framework) | TypeScript + React/Next.js/Svelte |
| `*.xcodeproj`, `Package.swift` | Swift/iOS |
| `settings.gradle` with android | Kotlin/Android |

Map detected technologies to workspace areas by examining directory structure. Look for common patterns:
- Monorepo: `crates/`, `packages/`, `apps/`, `services/`
- Standard: `src/`, `lib/`, `cmd/`, `internal/`
- Frontend: `frontend/`, `web/`, `app/`
- Mobile: `ios-app/`, `android-app/`, `apps/ios/`, `apps/android/`

### Phase 2: Confirm with User

Present detected workspace areas and ask the user to confirm or adjust. Gather:

1. **Workspace areas** — present detected modules with paths; let user add/remove/rename
2. **Project prefix** — short name for the command (e.g., `frk` → `/{frk}-code-review`). If a `{PREFIX}-issue` or `{PREFIX}-start` command already exists in `.claude/commands/`, suggest reusing that prefix.
3. **Architecture style** — hexagonal, layered, flat, microservices, or custom. This determines the dependency order for reviewing code (e.g., core → infrastructure → API → frontend for hexagonal).
4. **Project-specific rules** — any architectural constraints to respect during review. Examples: "CMS 3-layer architecture is intentional", "adapter pattern in infrastructure is production-ready", "greenfield — delete dead code directly". These become extra rules in the generated command.
5. **Quality check commands** — per workspace area. Auto-suggest from `references/tech-checks.md` based on detected tech, let user confirm or override.

### Phase 3: Generate the Command

Read the following references to compose the command:
- `assets/code-review-command.md` — structural template with placeholders
- `references/categories.md` — 7 categories with per-tech variants
- `references/tech-checks.md` — stack-specific quality checks

**Placeholder resolution:**

| Placeholder | Source |
|-------------|--------|
| `{ISSUE_COMMAND_NOTE}` | If `/{PREFIX}-issue` exists: ` — does NOT create GitHub issues (use /{PREFIX}-issue for that)`. Otherwise: empty. |
| `{SCOPE_TABLE}` | Workspace areas as argument → path mapping table. Always include `all` (full codebase, one area at a time) and `path/to/file` (single file or directory). |
| `{DEPENDENCY_ORDER}` | `Work in dependency order: X → Y → Z.` based on architecture style. |
| `{CATEGORIES}` | All 7 categories from `references/categories.md`. Include only the tech-specific items matching this project's stacks. Use thresholds for the project's languages. |
| `{STACK_CHECKS}` | Relevant sections from `references/tech-checks.md` only. Do not include stacks the project doesn't use. |
| `{ISSUE_COMMAND_REF}` | If `/{PREFIX}-issue` exists: ` (/{PREFIX}-issue)`. Otherwise: empty. |
| `{PROJECT_RULES}` | User-provided architectural constraints as additional rule bullets. |
| `{QUALITY_COMMANDS}` | `- **Quality checks**: ` followed by the per-area check commands. |

Write the assembled command to `.claude/commands/{PREFIX}-code-review.md`.

### Phase 4: Commit

Stage and commit:
```bash
git add .claude/commands/{PREFIX}-code-review.md
git commit -m "chore: add {PREFIX}-code-review command"
```

## Design Principles

- **Self-contained output** — the generated command works without this skill being installed
- **Tech-appropriate** — only includes categories, examples, thresholds, and checks relevant to the project's actual tech stacks
- **No false positives** — the generated command emphasizes verification before reporting
- **Integrates with existing workflow** — detects and references existing issue/start commands
- **Re-runnable** — can regenerate the command when repo structure changes
