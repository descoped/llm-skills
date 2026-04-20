# Loading semantics for Claude Code rules

The single biggest source of silent failure is a rule that *looks* present
in the repo but never reaches Claude. This file covers every mechanism in
detail — read it when wiring something non-trivial, debugging a rule that
"should" be loading, or answering a precise question about load order.

Source of truth: the [memory docs](https://code.claude.com/docs/en/memory).
If this file and the docs disagree, trust the docs.

## CLAUDE.md tree-walk

Claude Code reads CLAUDE.md by walking upward from the current working
directory. Every `CLAUDE.md` and `CLAUDE.local.md` it finds in the tree —
from the project root up through `~/.claude/CLAUDE.md` — is loaded **in
full** at session start. Files are concatenated, not overridden.

Within a given directory, `CLAUDE.local.md` is appended *after* `CLAUDE.md`,
so personal overrides load last and win on conflict at that level.

Subdirectory `CLAUDE.md` and `CLAUDE.local.md` files **below** the working
directory are *not* loaded at launch. They load on demand the first time
Claude reads a file in that subdirectory.

The managed-policy `CLAUDE.md` (below) always loads and cannot be excluded.

### Locations and scope

| Scope                | Location                                                                 | Purpose                                            |
| -------------------- | ------------------------------------------------------------------------ | -------------------------------------------------- |
| Managed policy       | macOS: `/Library/Application Support/ClaudeCode/CLAUDE.md`<br>Linux/WSL: `/etc/claude-code/CLAUDE.md`<br>Windows: `C:\Program Files\ClaudeCode\CLAUDE.md` | Org-wide, deployed via MDM / Group Policy / Ansible |
| User                 | `~/.claude/CLAUDE.md`                                                    | Personal preferences for all projects              |
| Project (shared)     | `./CLAUDE.md` or `./.claude/CLAUDE.md`                                   | Team-shared guidance via source control            |
| Project (local)      | `./CLAUDE.local.md`                                                      | Personal per-project notes; add to `.gitignore`    |
| Subdirectory         | `<subdir>/CLAUDE.md`, `<subdir>/CLAUDE.local.md`                         | Loaded on demand when reading files in `<subdir>`  |

### HTML comments are stripped

Block-level HTML comments in CLAUDE.md (`<!-- maintainer notes -->`) are
stripped before the content is injected into Claude's context. Useful for
human-only notes without spending tokens. Comments inside code blocks are
preserved.

### Additional directories via `--add-dir`

The `--add-dir` flag gives Claude access to directories outside the working
tree. By default their CLAUDE.md files are **not** loaded. Opt in with:

```bash
CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1 claude --add-dir ../shared-config
```

This pulls in `CLAUDE.md`, `.claude/CLAUDE.md`, `.claude/rules/*.md`, and
`CLAUDE.local.md` from the additional directory. `CLAUDE.local.md` is
skipped if you exclude `local` from `--setting-sources`.

### Excluding CLAUDE.md files in monorepos

Ancestor CLAUDE.md files from other teams can be skipped via
`claudeMdExcludes`, configurable at any settings layer (user, project,
local, managed):

```json
{
  "claudeMdExcludes": [
    "**/monorepo/other-team/CLAUDE.md",
    "/abs/path/other-team/.claude/rules/**"
  ]
}
```

Patterns match against **absolute** file paths using glob syntax. Arrays
merge across settings layers. Managed-policy CLAUDE.md files cannot be
excluded.

## `.claude/rules/` auto-discovery

At launch, Claude Code recursively discovers every `.md` file under
`.claude/rules/`. Organise by topic — `code-style.md`, `testing.md`,
`security.md` — and subdirectories are fine:

```
.claude/rules/
  code-style.md
  testing.md
  frontend/
    components.md
    styles.md
  backend/
    api.md
```

Rule files **without** `paths:` frontmatter load at launch with the same
priority as `.claude/CLAUDE.md`. They are always in context.

Rule files **with** `paths:` frontmatter are held in reserve and pulled in
only when Claude reads a file matching one of the globs.

### `paths:` frontmatter

```markdown
---
paths:
  - "src/api/**/*.ts"
  - "tests/**/*.test.ts"
---

# API rules
...
```

Common glob patterns:

| Pattern                | Matches                                  |
| ---------------------- | ---------------------------------------- |
| `**/*.ts`              | All TypeScript files anywhere            |
| `src/**/*`             | Everything under `src/`                  |
| `*.md`                 | Markdown files in the project root only  |
| `src/components/*.tsx` | React components in that exact directory |

Brace expansion works:

```yaml
paths:
  - "src/**/*.{ts,tsx}"
  - "lib/**/*.ts"
  - "tests/**/*.test.ts"
```

The trap: `paths:`-scoped rules do **not** load unless a matching file is
opened. If the user asks about the rule's subject matter in the abstract,
Claude will answer generically. Only scope rules the user never discusses
without first touching an associated file.

**Only `paths:` is recognised.** Cursor-style fields (`name`, `description`,
`globs`, `alwaysApply`) are silently ignored. A rule that *looks* scoped
because someone copied `globs:` from a Cursor project will actually load
unconditionally. Verify with the `InstructionsLoaded` hook (below) when
porting from another tool.

### User-level rules

`~/.claude/rules/*.md` applies to every project on the machine. Same shape
as project rules — with or without `paths:` frontmatter. User rules load
*before* project rules, giving project rules higher priority on conflict.

Use them for personal preferences that aren't project-specific: indentation
defaults, preferred testing style, personal workflow shortcuts.

### Symlinks for sharing across projects

`.claude/rules/` supports symlinks. Link a shared directory or individual
file from a canonical location:

```bash
ln -s ~/shared-claude-rules .claude/rules/shared
ln -s ~/company-standards/security.md .claude/rules/security.md
```

Circular symlinks are detected gracefully.

## `@path` imports

Inside any loaded markdown file (CLAUDE.md, CLAUDE.local.md, or rule files),
a line like `@path/to/file.md` expands the referenced file into context at
the import site.

- Relative paths resolve against the **importing** file, not the working
  directory. Absolute paths are also allowed.
- Imports can chain up to **5 hops**.
- The first time a project references an external import (outside the
  repo), Claude Code shows an approval dialog. Declining disables external
  imports silently — you will not be asked again.

Example:

```text
See @README for project overview and @package.json for npm commands.

# Git workflow
- @docs/git-instructions.md
```

Files already auto-discovered under `.claude/rules/` do **not** need an
`@import` from root — it just adds a line to maintain. Use `@import` for:

- Files *outside* `.claude/rules/` (READMEs, design docs, AGENTS.md)
- Forcing deterministic load order
- Pulling in worktree-shared personal rules (`@~/.claude/my-notes.md`)

### AGENTS.md interop

Claude Code reads `CLAUDE.md`, not `AGENTS.md`. If the repo already uses
`AGENTS.md` for other agents, bridge them by importing from CLAUDE.md:

```markdown
# CLAUDE.md
@AGENTS.md

## Claude-specific notes
<Claude Code-only additions here>
```

Both tools then read the same base instructions without duplication.

## What survives `/compact`

- **Project-root CLAUDE.md**: re-read from disk and re-injected after
  compaction.
- **Nested CLAUDE.md in subdirectories**: **not** re-injected. They reload
  the next time Claude opens a file in that subdirectory.
- **Conversation-only instructions**: lost. If an instruction disappears
  after compaction, it lived only in the conversation — move it into
  CLAUDE.md to make it persist.

## Debugging — what actually loaded?

Two tools make this concrete:

- **`/memory`** inside a session lists every loaded CLAUDE.md,
  CLAUDE.local.md, and rule file, and lets you open them in an editor. It
  also exposes the auto-memory toggle and a link to the auto-memory folder.
- **`InstructionsLoaded` hook** logs exactly which instruction files were
  loaded, when, and why. Essential for debugging `paths:`-scoped rules or
  subdirectory CLAUDE.md files that "should" be loading. See
  `/en/hooks#instructionsloaded` in the docs.

If a rule isn't being followed:

1. Run `/memory`. If the file isn't listed, Claude can't see it — check
   the path, `claudeMdExcludes`, or `paths:` frontmatter.
2. Read the rule content. Is it specific enough to verify? "Use 2-space
   indentation" works; "format code nicely" doesn't.
3. Check for conflicting rules across files. Where two rules contradict,
   Claude may pick arbitrarily.
4. If you need a *hard* guarantee ("never run `rm -rf`"), use
   `permissions.deny` in `settings.json` — rules are guidance, not
   enforcement.

## Auto memory vs CLAUDE.md

Both systems load at the start of every session; they complement each other.

|                    | CLAUDE.md / `.claude/rules/`                    | Auto memory                                        |
| ------------------ | ----------------------------------------------- | -------------------------------------------------- |
| Written by         | You                                             | Claude                                             |
| Contains           | Instructions and norms                          | Learnings Claude picked up during sessions         |
| Scope              | Project, user, managed                          | Per git repo (shared across worktrees)             |
| Loaded             | Full file, every session                        | First 200 lines / 25 KB of `MEMORY.md`, every session |
| Good for           | "Always do X" rules you care about              | Build commands Claude discovered, debugging notes   |

Auto-memory files live at `~/.claude/projects/<project>/memory/`. The
`<project>` path is derived from the git repository, so all worktrees of
the same repo share one directory. `MEMORY.md` is the index; Claude writes
detailed notes into topic files beside it as needed, reading them on demand.

Audit and edit auto-memory via `/memory`. Disable with
`{"autoMemoryEnabled": false}` in settings, or
`CLAUDE_CODE_DISABLE_AUTO_MEMORY=1`. To store auto-memory in a different
location, set `autoMemoryDirectory` in user/local settings (not project
settings — that would let a shared repo redirect writes to a sensitive
location).

Auto memory is **machine-local**. It does not sync across machines and is
not shared with teammates. Don't rely on it for anything that has to
travel with the code — that belongs in `.claude/rules/` or `CLAUDE.md`.

## Loading precedence at a glance

When multiple files give conflicting guidance, more specific wins. From
broadest to narrowest:

1. Managed-policy `CLAUDE.md` (org-wide, uncontested)
2. User `~/.claude/CLAUDE.md` and `~/.claude/rules/*.md`
3. Project `CLAUDE.md` / `.claude/CLAUDE.md` / `.claude/rules/*.md` (unscoped)
4. Project `.claude/rules/*.md` with a matching `paths:` glob
5. Subdirectory `CLAUDE.md` for the directory Claude is working in
6. `CLAUDE.local.md` at any level — applied *after* `CLAUDE.md` in the same
   directory

Where this file and the docs disagree, trust the docs.
