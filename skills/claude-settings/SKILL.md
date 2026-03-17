---
name: claude-settings
description: >
  Configure Claude Code project settings for autonomous, unattended work. Creates or updates
  .claude/settings.json (shared, committed) and .claude/settings.local.json (personal, gitignored)
  with tool permissions, hooks, environment variables, MCP servers, and plugin configuration.
  Eliminates unnecessary permission prompts by configuring allow/deny patterns tailored to the
  project's tech stack. Use when setting up a new project for Claude Code, reducing permission
  prompts, configuring hooks for linting or formatting, managing plugins or MCP servers, or when
  the user wants Claude Code to work autonomously with fewer interruptions. Also use when the user
  mentions settings.json, settings.local.json, permissions, or unattended operation.
---

# Claude Settings

Configure `.claude/settings.json` and `.claude/settings.local.json` for productive, unattended Claude Code work.

## File Distinction

| File | Committed | Purpose |
|------|-----------|---------|
| `.claude/settings.json` | Yes | Shared team settings: core permissions, env vars, plugins, MCP auto-approval |
| `.claude/settings.local.json` | No (gitignored) | Personal settings: hooks, deny overrides, disabled servers, plugin overrides |

Settings merge at runtime. Local overrides project, project overrides user. Permission arrays (`allow`, `deny`) are concatenated and deduplicated across scopes, not replaced. Deny rules always win over allow rules.

Consult `references/settings-guide.md` for the complete schema reference, permission patterns, hook patterns, and example configurations.

## Workflow

### Phase 1: Detect Project Context

1. Check if `.claude/` directory exists; create if needed
2. Read existing `settings.json` and `settings.local.json` if present
3. Auto-detect project tech stack:
   - `Cargo.toml` → Rust
   - `pyproject.toml` / `requirements.txt` → Python (check for uv, pip, poetry)
   - `go.mod` → Go
   - `build.gradle` / `pom.xml` → Java/Kotlin
   - `package.json` → TypeScript/JavaScript (check dependencies for React, Next.js, Svelte, etc.)
   - `*.xcodeproj` / `Package.swift` → Swift/iOS
4. Detect linter/formatter configs (`.eslintrc`, `ruff.toml`, `rustfmt.toml`, `.swiftlint.yml`, etc.)
5. Check for `.mcp.json` (MCP servers)
6. Check for existing plugins in settings

### Phase 2: Ask User Preferences

Present the user with these choices:

1. **Which file(s)?** — `settings.json` (shared), `settings.local.json` (personal), or both
2. **Permission level** — determines what goes into `permissions.allow`:
   - **Standard** — `Bash(BODY=*)`, `Bash(FIXED=*)` + core tools (recommended for shared repos)
   - **Full autonomy** — `Bash(*)` + core tools + `mcp__*` (maximum unattended work)
3. **Ask-tier permissions?** — Offer `permissions.ask` for semi-dangerous commands that should still prompt. Common candidates: `Bash(git push *)`, `Bash(git push --force *)`, `Bash(docker *)`. These allow the command but require a confirmation click — good middle ground between full autonomy and denial.
4. **Sensitive file protection?** — Offer standard deny patterns for secrets and credentials. Default ON:
   - `Read(./.env)`, `Read(./.env.*)`, `Read(./secrets/**)`, `Read(./config/credentials.json)`
   - Let user add or remove patterns based on their project structure
5. **Skill deny list?** — Offer to deny example-skills that may trigger unexpectedly (show list, let user select)
6. **Hooks?** — Propose auto-detected linting/formatting hooks based on tech stack. Ask which to include and whether they go in shared or local settings.
7. **Safety deny patterns?** — Propose deny rules for dangerous operations based on detected directory structure (e.g., data dirs, output dirs). These typically go in `settings.local.json`.
8. **Plugin preferences?** — Show detected/available plugins, ask which to enable/disable
9. **MCP servers?** — If `.mcp.json` exists, offer `enableAllProjectMcpServers: true` or selective `enabledMcpjsonServers`
10. **Environment variables?** — Propose relevant feature flags (e.g., `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`)
11. **Attribution?** — Offer to configure commit and PR attribution. Options:
    - Default (includes `Co-Authored-By: Claude` and emoji link)
    - Custom text
    - Disabled (`"attribution": { "commit": "", "pr": "" }`)
12. **Git instructions?** — If a custom git workflow skill is detected (e.g., `github-issues-workflow` commands in `.claude/commands/`), offer `includeGitInstructions: false` to disable built-in git workflow instructions that may conflict.
13. **Sandbox?** — For security-conscious teams, offer sandbox configuration with filesystem and network restrictions. See `references/settings-guide.md` for the full sandbox schema.
14. **Additional directories?** — For monorepos or multi-repo setups, offer `permissions.additionalDirectories` to grant Claude access to sibling directories outside the working tree (e.g., `["../shared-libs/", "../docs/"]`).

### Phase 3: Build Configuration

Assemble the settings JSON using patterns from `references/settings-guide.md`.

**For `settings.json` (shared):**
- `$schema` — always include for editor autocompletion
- `permissions.allow` — core tool permissions based on chosen level
- `permissions.ask` — semi-dangerous commands requiring confirmation
- `permissions.deny` — sensitive files, unwanted skills
- `permissions.additionalDirectories` — sibling directories if needed
- `env` — feature flags
- `attribution` — commit and PR attribution preferences
- `includeGitInstructions` — disable if custom git workflow skills are installed
- `enableAllProjectMcpServers` or `enabledMcpjsonServers`
- `enabledPlugins` — team-relevant plugins
- `sandbox` — filesystem and network restrictions if requested

**For `settings.local.json` (personal):**
- `hooks` — linting/formatting hooks for the detected tech stack
- `permissions.deny` — personal safety guards (protect data dirs)
- `disabledMcpjsonServers` — servers to disable locally
- `enabledPlugins` — personal overrides

### Phase 4: Backup Existing Settings

Before any modification, **always** create timestamped backups of existing settings files:

```bash
# Only backup files that exist
cp .claude/settings.json .claude/settings.json.bak.$(date +%Y%m%d-%H%M%S) 2>/dev/null
cp .claude/settings.local.json .claude/settings.local.json.bak.$(date +%Y%m%d-%H%M%S) 2>/dev/null
```

Tell the user the backup path(s) so they know how to restore if needed.

### Phase 5: Present Changes and Get Approval

1. **Show the current settings** (if any) alongside the proposed changes
2. **For each change, explain clearly:**
   - What the setting does
   - Why it's being added or changed
   - What the practical effect is (e.g., "this means Claude will no longer ask permission before running bash commands")
   - Any security implications (e.g., "`Bash(*)` allows ALL shell commands including destructive ones — deny patterns are your safety net")
3. **Show a diff-style summary** — highlight what's added, changed, or removed compared to existing settings
4. **Wait for explicit approval** before writing anything. Do not proceed on ambiguity — if the user seems uncertain, explain further.

### Phase 6: Write and Verify

1. After user approves, write the file(s)
2. Read back the written files to confirm they're valid JSON
3. If `.claude/` was created, verify that `.claude/settings.local.json` is in `.gitignore`
4. Remind the user:
   - Where backups are stored (and how to restore: `cp .claude/settings.json.bak.TIMESTAMP .claude/settings.json`)
   - That `settings.local.json` is gitignored automatically by Claude Code
   - They need to restart Claude Code or run `/reload-plugins` for changes to take effect

**Do NOT commit** — let the user decide when to commit.

## Key Principles

- **Always backup first** — never modify settings without creating a timestamped backup
- **Informed consent** — explain every change and its implications before writing; the user must approve explicitly
- **Eliminate prompts** — the primary goal is configuring permissions so Claude works without constant approval dialogs
- **Safe defaults** — always include deny patterns for sensitive files (`.env`, secrets)
- **Shared vs personal** — team-wide settings in `settings.json`; personal workflow in `settings.local.json`
- **Merge, don't replace** — if settings files exist, merge new config preserving user customizations
- **Non-destructive** — never remove existing settings the user added; only add or update
