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
7. Check for custom git workflow skills in `.claude/commands/`
8. Read the user's `~/.claude/CLAUDE.md` for any security guidelines or attribution preferences

### Phase 2: Generate and Present Complete Configuration

**Do NOT ask 14 individual questions.** Instead, auto-detect everything from Phase 1 and generate a complete, opinionated configuration. Present it as a single proposal with a brief summary of key choices. Let the user approve, reject, or request changes.

**Default configuration strategy:**

1. **Permission level**: Standard (`Bash(BODY=*)`, `Bash(FIXED=*)` + core tools). This is the right default for most projects.
2. **Sensitive file protection**: Always ON — deny `Read(./.env)`, `Read(./.env.*)`, `Read(./secrets/**)`
3. **Example skill deny list**: Always include — prevents accidental triggering of document/artifact skills
4. **MCP servers**: If `.mcp.json` exists, include `enableAllProjectMcpServers: true`. If Playwright is detected in plugins, add `mcp__playwright__*` and `mcp__plugin_playwright_playwright__*` to allow.
5. **Environment variables**: Include `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS: "1"` by default
6. **Attribution**: Check user's `~/.claude/CLAUDE.md` for attribution preferences. If it says to disable attribution, set `"attribution": { "commit": "", "pr": "" }`. Otherwise, leave as default.
7. **Git instructions**: If custom git workflow commands exist in `.claude/commands/`, set `includeGitInstructions: false`
8. **Plugins**: Preserve any existing `enabledPlugins` from current settings
9. **`$schema`**: Always omit — it adds noise and Claude Code doesn't need it for validation

**Generate the complete JSON** and present it in a single code block. Below it, add a short bullet list of key choices and why. Example:

```
**Proposed `.claude/settings.json`:**
[full JSON here]

**Key choices:**
- Standard permissions (Bash(BODY=*)/Bash(FIXED=*) + core tools) — eliminates prompts while maintaining rtk hook compatibility
- Sensitive file deny — .env and secrets protected
- Example skills denied — prevents accidental document/artifact skill triggering
- Agent teams enabled — allows parallel agent work
- Attribution disabled — per your security guidelines
```

Then ask: "Want me to write this? Any changes?"

### Phase 3: Backup Existing Settings

Before any modification, **always** create timestamped backups of existing settings files:

```bash
# Only backup files that exist
cp .claude/settings.json .claude/settings.json.bak.$(date +%Y%m%d-%H%M%S) 2>/dev/null
cp .claude/settings.local.json .claude/settings.local.json.bak.$(date +%Y%m%d-%H%M%S) 2>/dev/null
```

Tell the user the backup path(s) so they know how to restore if needed.

### Phase 4: Write and Verify

1. After user approves, write the file(s) using the Write tool
2. Read back the written files to confirm they're valid JSON
3. If `.claude/` was created, verify that `.claude/settings.local.json` is in `.gitignore`
4. Remind the user that they may need to restart Claude Code or run `/reload-plugins` for changes to take effect

**Do NOT commit** — let the user decide when to commit.

## Required Fields for `settings.json`

Every generated `settings.json` MUST include all of these fields. Missing any of them is a bug:

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  },
  "permissions": {
    "allow": [
      "Bash(BODY=*)",
      "Bash(FIXED=*)",
      "Read",
      "Write",
      "Edit",
      "WebFetch",
      "WebSearch"
    ],
    "deny": [
      "Read(./.env)",
      "Read(./.env.*)",
      "Read(./secrets/**)"
    ]
  },
  "enabledPlugins": {}
}
```

Additional fields to include when detected:
- `"mcp__playwright__*"` and `"mcp__plugin_playwright_playwright__*"` in `permissions.allow` — when Playwright plugin is enabled
- `"mcp__*"` in `permissions.allow` — when the user requests full autonomy or has MCP servers
- `"enableAllProjectMcpServers": true` — when `.mcp.json` exists
- `"attribution": { "commit": "", "pr": "" }` — when user's CLAUDE.md disables attribution
- `"includeGitInstructions": false` — when custom git workflow commands are detected
- Example skill deny patterns — always include (see `references/settings-guide.md` for the full list)

## Key Principles

- **Action-oriented** — detect, generate, propose, write. Do not stall on questions.
- **One proposal, one approval** — present the complete configuration once. Do not ask 14 individual questions.
- **Always backup first** — never modify settings without creating a timestamped backup
- **Eliminate prompts** — the primary goal is configuring permissions so Claude works without constant approval dialogs
- **Safe defaults** — always include deny patterns for sensitive files (`.env`, secrets)
- **Shared vs personal** — team-wide settings in `settings.json`; personal workflow in `settings.local.json`
- **Merge, don't replace** — if settings files exist, merge new config preserving user customizations
- **Non-destructive** — never remove existing settings the user added; only add or update
