# Settings Guide

Complete reference for `.claude/settings.json` and `.claude/settings.local.json` configuration. Use this as a menu to compose project-specific settings.

## Table of Contents

1. [Schema](#schema)
2. [Permissions](#permissions)
3. [Environment Variables](#environment-variables)
4. [Hooks](#hooks)
5. [Plugins](#plugins)
6. [MCP Servers](#mcp-servers)
7. [Sandbox](#sandbox)
8. [Other Settings](#other-settings)
9. [What Goes Where](#what-goes-where)
10. [Example Configurations](#example-configurations)

---

## Schema

Always include the `$schema` line for editor autocompletion and validation:

```json
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json"
}
```

---

## Permissions

Rules evaluate in order: deny first, then ask, then allow. First match wins.

### Allow Patterns

**Core tools** (include in almost every project):

| Pattern | What it allows |
|---------|----------------|
| `Read` | Read any file |
| `Write` | Create/overwrite files |
| `Edit` | Edit existing files |
| `WebFetch` | Fetch web content |
| `WebSearch` | Search the web |

**Bash patterns** (choose based on trust level):

| Pattern | Level | Description |
|---------|-------|-------------|
| `Bash(BODY=*)`, `Bash(FIXED=*)` | Standard | Allows bash with rtk hook compatibility |
| `Bash(*)` | Full | Allows all bash commands unconditionally |
| `Bash(npm run *)` | Selective | Only npm run commands |
| `Bash(git *)` | Selective | Only git commands |
| `Bash(cargo *)` | Selective | Only cargo commands |
| `Bash(uv run *)` | Selective | Only uv-managed commands |
| `Bash(go *)` | Selective | Only go commands |

**MCP patterns:**

| Pattern | What it allows |
|---------|----------------|
| `mcp__*` | All tools from all MCP servers |
| `mcp__servername__*` | All tools from a specific server |
| `mcp__servername__toolname` | A single tool from a specific server |
| `mcp__playwright__*` | All Playwright tools |

**Skill patterns:**

| Pattern | What it allows |
|---------|----------------|
| `Skill(plugin:skill-name)` | A specific skill |
| `Skill(*)` | All skills |

**Other tool patterns:**

| Pattern | What it allows |
|---------|----------------|
| `WebFetch(domain:example.com)` | Fetch from a specific domain |
| `Read(./.env)` | Read a specific file |
| `Edit(src/**)` | Edit files matching a glob |

### Deny Patterns

**Sensitive files** (recommended for all projects):

```json
"deny": [
  "Read(./.env)",
  "Read(./.env.*)",
  "Read(./secrets/**)",
  "Read(./config/credentials.json)"
]
```

**Dangerous bash commands** (protect specific directories):

```json
"deny": [
  "Bash(rm -rf output*)",
  "Bash(rm -r output*)",
  "Bash(rm output*)",
  "Bash(rm -rf data*)",
  "Bash(rm -r data*)"
]
```

**Unwanted skills** (prevent accidental triggering of example skills):

```json
"deny": [
  "Skill(example-skills:xlsx)",
  "Skill(example-skills:docx)",
  "Skill(example-skills:pptx)",
  "Skill(example-skills:doc-coauthoring)",
  "Skill(example-skills:pdf)",
  "Skill(example-skills:internal-comms)",
  "Skill(example-skills:algorithmic-art)",
  "Skill(example-skills:web-artifacts-builder)",
  "Skill(example-skills:mcp-builder)",
  "Skill(example-skills:theme-factory)",
  "Skill(example-skills:brand-guidelines)",
  "Skill(example-skills:slack-gif-creator)"
]
```

### Ask Patterns

The `ask` tier sits between allow and deny — commands match but require a confirmation click. Useful for semi-dangerous operations you want to permit but still review.

```json
"ask": [
  "Bash(git push *)",
  "Bash(git push --force *)",
  "Bash(docker *)",
  "Bash(kubectl delete *)"
]
```

### Additional Directories

Grant Claude access to directories outside the working tree. Useful for monorepos or multi-repo setups where Claude needs to read/write sibling directories:

```json
"permissions": {
  "additionalDirectories": ["../shared-libs/", "../docs/", "../proto/"]
}
```

### Permission Modes

| Key | Values | Purpose |
|-----|--------|---------|
| `permissions.defaultMode` | `"default"`, `"acceptEdits"`, `"bypassPermissions"` | Default permission mode on startup |

---

## Environment Variables

Set via the `env` field. Applied to every session.

| Variable | Value | Purpose |
|----------|-------|---------|
| `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` | `"1"` | Enable agent teams (multiple Claude instances collaborating) |
| `CLAUDE_CODE_ENABLE_TELEMETRY` | `"1"` | Enable telemetry |
| `OTEL_METRICS_EXPORTER` | `"otlp"` | OpenTelemetry metrics export |

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

---

## Hooks

Hooks run shell commands at lifecycle events. Always trail commands with `; true` or `2>/dev/null` to prevent hook failures from blocking tool use.

### PreToolUse

Runs before a tool executes. Use for validation and auto-fixing.

**Lint before git commit (Python/uv):**
```json
{
  "matcher": "Bash(git commit*)",
  "hooks": [{
    "type": "command",
    "command": "cd backend && uv run ruff check --quiet --fix . 2>/dev/null; cd backend && uv run ruff format --quiet . 2>/dev/null; true"
  }]
}
```

**Lint before git commit (Rust):**
```json
{
  "matcher": "Bash(git commit*)",
  "hooks": [{
    "type": "command",
    "command": "cargo fmt --all 2>/dev/null; cargo clippy --all-targets -- -D warnings 2>/dev/null; true"
  }]
}
```

**Lint before git commit (Frontend/bun):**
```json
{
  "matcher": "Bash(git commit*)",
  "hooks": [{
    "type": "command",
    "command": "cd frontend && bun run check 2>/dev/null; true"
  }]
}
```

**Lint before git commit (Go):**
```json
{
  "matcher": "Bash(git commit*)",
  "hooks": [{
    "type": "command",
    "command": "go fmt ./... 2>/dev/null; go vet ./... 2>/dev/null; true"
  }]
}
```

### PostToolUse

Runs after a tool executes. Use for auto-formatting after edits.

**Fix markdown trailing whitespace:**
```json
[
  {
    "matcher": "Edit",
    "hooks": [{
      "type": "command",
      "command": "python3 scripts/claude/fix-md-trailing-whitespace.py"
    }]
  },
  {
    "matcher": "Write",
    "hooks": [{
      "type": "command",
      "command": "python3 scripts/claude/fix-md-trailing-whitespace.py"
    }]
  }
]
```

**Auto-format after edits (Python/uv):**
```json
{
  "matcher": "Edit|Write",
  "hooks": [{
    "type": "command",
    "command": "uv run ruff format --quiet . 2>/dev/null; true"
  }]
}
```

**Auto-format after edits (Rust):**
```json
{
  "matcher": "Edit|Write",
  "hooks": [{
    "type": "command",
    "command": "cargo fmt --all 2>/dev/null; true"
  }]
}
```

### Hook Structure

The full hooks config nests under the `hooks` key:

```json
{
  "hooks": {
    "PreToolUse": [ { "matcher": "...", "hooks": [...] } ],
    "PostToolUse": [ { "matcher": "...", "hooks": [...] } ]
  }
}
```

Available events: `PreToolUse`, `PostToolUse`, `PostToolUseFailure`, `UserPromptSubmit`, `Notification`, `Stop`, `SubagentStart`, `SubagentStop`, `SessionStart`, `SessionEnd`, `PreCompact`.

---

## Plugins

### enabledPlugins

Map of plugin identifiers to enabled state:

```json
{
  "enabledPlugins": {
    "plugin-name@marketplace-name": true,
    "another-plugin@marketplace-name": false
  }
}
```

Common plugins:

| Plugin | Marketplace | Purpose |
|--------|-------------|---------|
| `frontend-design` | `claude-plugins-official` | Frontend UI design guidance |
| `playwright` | `claude-plugins-official` | Browser testing and automation |
| `security-guidance` | `claude-plugins-official` | Security checks on file edits |
| `skill-creator` | `claude-plugins-official` | Create and test skills |
| `vercel` | `claude-plugins-official` | Vercel deployment integration |

### extraKnownMarketplaces

Register additional plugin marketplaces:

```json
{
  "extraKnownMarketplaces": {
    "my-tools": {
      "source": "github",
      "repo": "org/claude-plugins"
    }
  }
}
```

---

## MCP Servers

### Auto-approve all project MCP servers

```json
{
  "enableAllProjectMcpServers": true
}
```

### Selective approval

```json
{
  "enabledMcpjsonServers": ["memory", "github"]
}
```

### Disable specific servers locally

Use in `settings.local.json` to suppress servers not relevant to your environment:

```json
{
  "disabledMcpjsonServers": ["jetbrains", "vscode"]
}
```

---

## Sandbox

Filesystem and network sandboxing for bash commands:

```json
{
  "sandbox": {
    "enabled": true,
    "autoAllowBashIfSandboxed": true,
    "excludedCommands": ["docker", "git"],
    "filesystem": {
      "allowWrite": ["//tmp/build", "~/.kube"],
      "denyRead": ["~/.aws/credentials"]
    },
    "network": {
      "allowedDomains": ["github.com", "*.npmjs.org"],
      "allowLocalBinding": true
    }
  }
}
```

Path prefixes: `//` = absolute, `~/` = home-relative, `/` = settings-dir-relative.

---

## Attribution

Control how Claude attributes its contributions in git commits and PRs.

**Default behavior:** adds `Co-Authored-By: Claude` trailer and emoji link to commits and PRs.

**Disable all attribution:**
```json
{
  "attribution": {
    "commit": "",
    "pr": ""
  }
}
```

**Custom attribution:**
```json
{
  "attribution": {
    "commit": "AI-assisted\n\nCo-Authored-By: AI Assistant <ai@example.com>",
    "pr": "AI-assisted"
  }
}
```

The `attribution` setting supersedes the deprecated `includeCoAuthoredBy`.

## Git Workflow Instructions

Claude Code includes built-in git commit and PR workflow instructions in its system prompt. If you use custom git workflow skills (e.g., `github-issues-workflow`), these may conflict.

**Disable built-in git instructions:**
```json
{
  "includeGitInstructions": false
}
```

This removes Claude's default commit/PR behavior, letting your custom skills take full control.

## Other Settings

| Key | Type | Purpose |
|-----|------|---------|
| `model` | string | Override default model (e.g., `"claude-sonnet-4-6"`) |
| `effortLevel` | `"low"` / `"medium"` / `"high"` | Persist effort level across sessions |
| `alwaysThinkingEnabled` | boolean | Enable extended thinking by default |
| `language` | string | Preferred response language (e.g., `"japanese"`) |
| `teammateMode` | `"auto"` / `"in-process"` / `"tmux"` | Agent team display mode |
| `cleanupPeriodDays` | number | Session cleanup period (default: 30) |
| `respectGitignore` | boolean | `@` file picker respects .gitignore (default: true) |

---

## What Goes Where

### settings.json (committed, shared)

Everything the team needs for productive work:

- `$schema` for editor autocompletion
- `permissions.allow` — core tool permissions
- `permissions.deny` — sensitive files, unwanted skills
- `env` — feature flags the team uses
- `enableAllProjectMcpServers` or `enabledMcpjsonServers`
- `enabledPlugins` — team-wide plugin selections
- `extraKnownMarketplaces` — team plugin marketplaces

### settings.local.json (gitignored, personal)

Everything specific to your local setup:

- `hooks` — personal linting/formatting workflow
- `permissions.deny` — protect local data directories
- `disabledMcpjsonServers` — IDE-specific servers you don't use
- `enabledPlugins` — personal plugin overrides
- `model` or `effortLevel` — personal model preferences

---

## Example Configurations

### Standard autonomy (settings.json)

```json
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
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
  }
}
```

### Full autonomy (settings.json)

```json
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "permissions": {
    "allow": [
      "Bash(*)",
      "Read",
      "Write",
      "Edit",
      "WebFetch",
      "WebSearch",
      "mcp__*"
    ],
    "ask": [
      "Bash(git push --force *)"
    ],
    "deny": [
      "Read(./.env)",
      "Read(./.env.*)",
      "Read(./secrets/**)",
      "Skill(example-skills:xlsx)",
      "Skill(example-skills:docx)",
      "Skill(example-skills:pptx)",
      "Skill(example-skills:doc-coauthoring)",
      "Skill(example-skills:pdf)",
      "Skill(example-skills:internal-comms)",
      "Skill(example-skills:algorithmic-art)",
      "Skill(example-skills:web-artifacts-builder)",
      "Skill(example-skills:mcp-builder)",
      "Skill(example-skills:theme-factory)",
      "Skill(example-skills:brand-guidelines)",
      "Skill(example-skills:slack-gif-creator)"
    ]
  },
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  },
  "attribution": {
    "commit": "",
    "pr": ""
  },
  "includeGitInstructions": false,
  "enableAllProjectMcpServers": true
}
```

### Personal workflow (settings.local.json)

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash(git commit*)",
        "hooks": [{
          "type": "command",
          "command": "cd backend && uv run ruff check --quiet --fix . 2>/dev/null; cd frontend && bun run check 2>/dev/null; true"
        }]
      }
    ]
  },
  "permissions": {
    "deny": [
      "Bash(rm -rf output*)",
      "Bash(rm -r output*)",
      "Bash(rm output*)"
    ]
  },
  "disabledMcpjsonServers": ["jetbrains"],
  "enabledPlugins": {
    "frontend-design@claude-plugins-official": false
  }
}
```
