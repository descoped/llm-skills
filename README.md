# llm-skills

A collection of LLM skills for AI coding agents. Skills are customizable workflows that teach LLMs to perform specific tasks with repeatable, standardized execution.

## Skills

| Skill | What it does |
|---|---|
| [github-issues-workflow](#github-issues-workflow) | Bootstrap an issue-driven development workflow for monorepo projects |
| [code-review](#code-review) | Generate a project-specific clean code review command |
| [claude-settings](#claude-settings) | Configure Claude Code for autonomous, unattended work |
| [domain-finder](#domain-finder) | Find creative, available domain names for projects and businesses |
| [statusline](#statusline) | Install and customize a compact Claude Code status line |
| [vite-chunk-split](#vite-chunk-split) | Fix Vite single-chunk bundles that slow page loads |
| [slack-message](#slack-message) | Write Slack messages with proper Slack markup |
| [session-snapshot](#session-snapshot) | Save and restore Claude Code session state across `/compact` boundaries |

## Installation

### Claude Code

1. Add this repository as a plugin marketplace:

   ```
   /plugin https://github.com/descoped/llm-skills
   ```

2. Select a skill from the plugin browser to install it.

3. Restart Claude Code for the skill to become available.

### Manual

Copy the skill directory into your project's `.claude/skills/` or use the packaged `.skill` file from the `dist/` directory.

## Quick Start

Once a skill is installed, invoke it with a slash command using the `/llm-skills:` namespace:

```
/llm-skills:github-issues-workflow
/llm-skills:code-review
/llm-skills:claude-settings
```

You can also mention the skill's purpose in plain language — Claude will trigger the skill automatically based on its description. For example, saying "help me find a domain name for my new project" triggers `domain-finder`.

---

## github-issues-workflow

Bootstraps an issue-driven development workflow for monorepo projects. Given a project's tech stack and repo details, it generates all the infrastructure needed for structured issue tracking with Claude Code.

**What it generates:**

| Artifact | Location | Purpose |
|----------|----------|---------|
| Label setup script | `scripts/github/setup-labels.sh` | Creates area, type, priority, and status labels |
| Issue templates | `.github/ISSUE_TEMPLATE/` | General, bug report, and feature request templates |
| PR template | `.github/PULL_REQUEST_TEMPLATE.md` | Standardized pull request format |
| Claude Code commands | `.claude/commands/` | Four slash commands for the full issue lifecycle |

**Supported tech stacks:** Rust, Python, Go, Java | React, Next.js, Svelte v5 | iOS, Android | Tooling crates

### The Workflow Concept

This skill implements an **issue-driven development workflow** — a structured process where every code change traces back to a GitHub issue and follows a predictable lifecycle from creation to merge.

The core idea: issues stay **solution-agnostic** (describing *what* and *why*, never *how*), while implementation details live in tracked files alongside the code. This separates the problem definition from the solution, keeping issues clean and reusable as documentation.

**Four commands orchestrate the lifecycle:**

```
/{PREFIX}-issue    Create a solution-agnostic GitHub issue
       |
/{PREFIX}-start    Branch, write design.md + task.md, implement, open PR
       |
/{PREFIX}-review   Review PR with tech-specific checklist
       |
/{PREFIX}-address  Address review feedback systematically
```

When work begins on an issue, two mandatory documents are created:

- **`design.md`** — A self-contained specification that copies all relevant context verbatim. It never references external files by path, so it remains valid even if source documents are deleted or moved. This is the permanent record of *what was built and why*.

- **`task.md`** — A checkbox task list that tracks implementation progress. Each task is checked off as completed, providing a clear audit trail.

These files live in `.claude/issues/issue-N/` during active work and are archived to `.claude/history/issue-N/` after the PR merges:

```
During work:                    After merge:
.claude/issues/                 .claude/history/
  issue-42/                       issue-42/
    design.md                       design.md
    task.md                         task.md
```

The full `/{PREFIX}-start` lifecycle covers 9 phases:

1. **Fetch and analyze** — Read the issue and all referenced documents
2. **Setup** — Assign, branch, create design.md and task.md
3. **Implement** — Work through tasks, checking off each one
4. **Verify** — Run all checks, confirm acceptance criteria
5. **Commit and PR** — Stage specific files, push, create PR
6. **Post-PR** — Run tests, update issue body, post results
7. **Review** — Structured review via `/{PREFIX}-review`
8. **Merge** — Squash merge after CI passes
9. **Archive** — Move issue folder to history, update references

This approach works because it gives the AI agent (and human developers) a repeatable, auditable process. Every issue has a design rationale, every PR traces to an issue, and every completed task has a history.

### Post-Install: Register GitHub Labels

After the skill generates your project files, you **must** run the label setup script to register labels on your GitHub repository before creating issues:

```bash
bash scripts/github/setup-labels.sh
```

This creates the area, type, priority, and status labels that the issue templates and Claude Code commands depend on. Without these labels, the `/{PREFIX}-issue` command cannot apply proper categorization.

---

## code-review

Generates a project-specific `/{PREFIX}-code-review` Claude Code command tailored to the repo's tech stacks, module structure, and architecture.

**How it works:**

1. Auto-detects tech stacks from repo markers (`Cargo.toml`, `package.json`, `go.mod`, etc.)
2. Maps modules to workspace areas with scope keywords
3. Generates a self-contained code review command in `.claude/commands/`

**The generated command performs deep analysis across 7 clean code categories:**

| Category | What it catches |
|----------|----------------|
| SRP | Functions/types doing too many things |
| DRY | Duplicated logic, copy-pasted patterns |
| Dead Code | Unused functions, imports, unreachable branches |
| Stubs | TODOs, placeholder implementations, empty catch blocks |
| Complexity | Long functions, deep nesting, too many parameters |
| Coupling | Circular dependencies, leaky abstractions, feature envy |
| Naming | Misleading names, generic names, inconsistent conventions |

**Supported tech stacks:** Rust, Python, Go, Java, Kotlin | TypeScript, React, Next.js, Svelte 5 | Swift/iOS, Kotlin/Android

**Integrates with github-issues-workflow** — if `/{PREFIX}-issue` exists, findings can be turned into issues directly.

---

## claude-settings

Configures `.claude/settings.json` and `.claude/settings.local.json` for autonomous, unattended Claude Code work. Auto-detects tech stacks and proposes permission, hook, plugin, and MCP configurations.

**What it configures:**

| Category | Examples |
|----------|----------|
| Permissions | Tool allow/ask/deny patterns, sensitive file protection, MCP access |
| Hooks | Pre-commit linting, post-edit formatting (per tech stack) |
| Safety | Deny patterns for dangerous commands, sandbox configuration |
| Plugins | Enable/disable plugins, register marketplaces |
| Attribution | Commit/PR attribution control |
| Git workflow | Disable built-in instructions when custom skills are installed |

**Key features:**

- Always creates timestamped backups before modifying settings
- Shows diff-style summary with security implications before writing
- Merges with existing settings (never replaces)
- Separates shared team settings from personal local settings

---

## domain-finder

Finds creative, available domain names for projects and businesses. Generates 40-50 candidates per batch, checks real availability via `whois`, and iterates until you find one you love.

**5 naming strategies:**

| Strategy | Weight | Example |
|----------|--------|---------|
| Invented words | ~40% | `cletho`, `brantol`, `jempra` |
| Word blends | ~20% | `pagefold`, `markfold` |
| Metaphors | ~15% | `kiln`, `loom`, `bastion` |
| Compressed phrases | ~10% | `structo`, `flipa` |
| Modified real words | ~15% | `timbr`, `krystal`, `simpel` |

**Supports:** `.com`, `.dev`, `.io`, `.no`, `.ai`, and any TLD.

---

## statusline

Installs and customizes a compact Claude Code status line. Self-contained Bash script showing project, auto-compressed path, git branch with dirty-state flags, model name with context window and thinking level, context-usage bar with tokens, and session cost.

**Example output:**

```
krantho  ~/Code/krantho  ⎇ master [?!+]  │  opus-4-7[1m] [think:max]  │  ███░░░░░ 42%  │  ↑450k ↓85k  │  $2.145
```

**Key features:**

| Feature | What it does |
|---|---|
| Adaptive path compression | Four tiers: full → `../parent/leaf` → `../leaf` → `../…truncated`. Uses `..` for hidden path segments, `…` for a truncated leaf |
| Git dirty flags | `?` untracked, `!` modified, `+` staged, `x` deleted — single `git status` pass |
| Model label | Strips `claude-` prefix, extracts context-window tag (`[1m]`, `[200k]`), removes thinking markers (shown separately) |
| Color-coded context bar | Green <50%, yellow <80%, red ≥80% |
| Detached-HEAD fallback | Shows short SHA when `branch --show-current` is empty |

**Install scope:** global (`~/.claude/`) or per-project (`<repo>/.claude/`). The skill merges `settings.json` safely via `jq` — never overwrites.

**Dependencies:** `jq` required. `git` and `tput` optional (features degrade gracefully).

---

## vite-chunk-split

Fixes Vite single-chunk bundles that cause slow page loads and break MCP Playwright testing. Converts static page imports to `React.lazy`, adds Suspense boundaries, and configures vendor chunk splitting in `vite.config.ts`.

**When to use:**

- Build output has a single JS chunk over 500KB
- MCP Playwright times out on `browser_navigate` or `browser_snapshot`
- Pages load heavy libraries they don't use (ReactFlow on a settings page, CodeMirror on a dashboard)

**6-step workflow:**

1. Diagnose current chunk distribution
2. Identify the router and static page imports
3. Map heavy dependencies to consumer pages
4. Convert static imports to `React.lazy` (keeping layouts static)
5. Add `<Suspense>` boundaries inside layouts
6. Configure `manualChunks` for vendor splitting

**Supports:** React, Vue (`defineAsyncComponent`), and SvelteKit (already lazy by default).

**Known-heavy library table** covers `monaco-editor`, `@codemirror/*`, `@mui/material`, `recharts`, `react-syntax-highlighter`, `@xyflow/react`, and more.

---

## slack-message

Writes Slack messages using plain-text Slack markup — direct, concise, and copy-paste ready.

**What it covers:**

- Slack-specific markup reference (bold, italic, code, links, blockquotes, lists)
- ASCII table formatting for Slack's monospace code blocks
- Tone and voice guidelines (direct, personal, no corporate speak)
- Six message patterns: status update, milestone, bug report, asking for input, PR notification, data summary with table

**Output format:** Raw Slack markup wrapped in a code block — copy-paste directly into Slack.

---

## session-snapshot

Saves and restores Claude Code session state across `/compact` boundaries. Writes a dated handoff markdown to `.claude/session-state/` before compact, reads and deletes it after — so the next turn resumes with full intent, decisions, and the next-step sequence intact.

**Two verbs:**

| Verb | When | What it does |
|---|---|---|
| `save` | Before `/compact` — "we need to compact", "context is full", "dump the plan" | Writes `YYYYMMDDTHHMMZ_session-state.md` with goal, locked-in decisions, WIP, next-step sequence, open questions, key file anchors |
| `restore` | After `/compact` — "catch up", "pick up where we left off" | Reads the most recent snapshot, summarizes in 3–5 lines, deletes the file |

**Key properties:**

- **Project-local, gitignored, ephemeral** — snapshots live in `<repo>/.claude/session-state/` and are auto-removed after restore
- **Privacy guardrail** — no IPs, hostnames, account IDs, credentials, or device identifiers; uses RFC 5737 / RFC 2606 reserved ranges for examples
- **First-run setup** is invisible — creates the directory and appends a `.gitignore` entry on first `save`
- **UTC-prefixed filenames** sort chronologically; minute-precision handles same-day snapshots

**Why it matters:** `/compact` replaces conversation history with a model-generated summary that's strong on "what happened" but weak on "what's decided, what's next, what's blocked". In long sessions, the lossy summary becomes the bottleneck. A snapshot shifts the load: before compact, Claude + user jointly produce a high-signal handoff doc; after compact, Claude reads it and resumes.

---

## Repository Structure

```
skills/                          Skill source directories
  github-issues-workflow/
    SKILL.md                     Skill metadata and instructions
    scripts/                     Executable templates
    references/                  Tech stack and command specifications
    assets/                      Issue/PR templates, Claude command templates
  code-review/
    SKILL.md                     Generator workflow
    references/                  Categories and tech-specific checks
    assets/                      Command template
  claude-settings/
    SKILL.md                     Settings configuration workflow
    references/                  Schema reference and patterns
  domain-finder/
    SKILL.md                     Domain name discovery workflow
    references/                  Naming strategies and availability checks
  statusline/
    SKILL.md                     Install + customize workflow
    assets/statusline.sh         Self-contained status line script
    references/                  Post-install customization guide
  vite-chunk-split/
    SKILL.md                     Chunk-split workflow (React/Vue/SvelteKit)
  slack-message/
    SKILL.md                     Skill metadata and instructions
  session-snapshot/
    SKILL.md                     Save + restore workflow (pre-/post-compact)
.claude-plugin/
  marketplace.json               Skills manifest for Claude Code
```

## License

Apache 2.0
