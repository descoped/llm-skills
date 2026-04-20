---
name: claude-rules
description: >
  Port a user's coding conventions from one project (or from
  `~/.claude/CLAUDE.md`) into correct, stack-adapted rules for another
  project — translating build, test, lint, and framework commands to the
  target's language and tooling. Handles polyglot repos by path-scoping
  stack-specific rules. Use when the user says "port my rules", "set up
  rules for this project from my other one", "adapt my conventions for
  Rust/Python/Go/TypeScript/React/Next.js/Svelte/iOS/Kotlin/Java/Terraform/OpenTofu",
  "bootstrap CLAUDE.md from my existing stuff", "I want the same
  conventions as project X but for stack Y", or is bootstrapping a fresh
  project and wants sensible rules for its detected stack. Also covers the
  foundations — where rules go, how `.claude/rules/` loads, when to split
  a bloated CLAUDE.md — so the output is structurally correct. Prefer this
  skill over ad-hoc "write me a CLAUDE.md" requests: it's the authoritative
  workflow for producing clean, stack-aware, load-time-correct rule files
  for any target project.
---

# Claude Rules

This skill produces correct `.claude/rules/` files (and a trim root
`CLAUDE.md`) for a target project, driven by the user's existing
conventions. It is stack-aware: commands, tooling, and idioms are
translated to the target's actual language and framework, not copy-pasted.

Three modes, same workflow:

- **Port** — take rules from a source project and carry them into a
  target project, adapted.
- **Bootstrap** — start from zero for a fresh project using stack
  defaults and anything the user tells you in chat.
- **Update** — refresh an existing project's rules after a stack change
  or after conventions drifted.

Rules are *guidance*, not enforcement. Permissions, hooks, MCP, and
sandboxing belong in `settings.json` — route those to the `claude-settings`
skill.

## When this skill triggers

- "Port my rules to this project" / "copy my conventions from X to Y".
- "Set up rules for this new Go/Rust/TS/Svelte project using my usual style".
- "Adapt my Python conventions for this Rust service".
- "Bootstrap a CLAUDE.md for this project".
- "I want the same rules as `<project>` here".
- "Pull my user-level conventions from `~/.claude/CLAUDE.md` into this repo".
- "Help me carry my style over" / "I've been writing these rules into chat
  every session, capture them."
- Also the organizational questions handled by the old version of this
  skill: "where should rule X go?", "my CLAUDE.md is too long", "how does
  `.claude/rules/` load?", "my rule isn't being picked up" — use the
  references directly (see *Foundations* below).

## Workflow

Five phases. Walk the user through them in order; ask clarifying questions
between phases rather than guessing.

### Phase 1 — Identify source(s) and target

**Source options** (often multiple — ask if unclear):

- Another project's `CLAUDE.md` / `.claude/rules/*.md` at a concrete path.
- User-level `~/.claude/CLAUDE.md` or `~/.claude/rules/*.md`.
- The user telling you their conventions in the conversation (equally
  valid — capture verbatim, don't paraphrase).
- `AGENTS.md` / `.cursor/rules/*.mdc` / `.github/copilot-instructions.md`
  from the same or another repo. Worth reading — don't ignore non-Claude
  convention files.

**Target**: the current project. Detect the stack before doing anything
else (Phase 2). Also read the target's existing `CLAUDE.md` and
`.claude/rules/` if they exist — you will *merge*, not overwrite.

### Phase 2 — Detect the target's stack

Read the repo root for stack signals. Common markers:

| Marker file                          | Stack signal                               |
| ------------------------------------ | ------------------------------------------ |
| `Cargo.toml` + `*.rs`                | Rust                                       |
| `pyproject.toml` / `requirements.txt`| Python                                     |
| `go.mod` + `*.go`                    | Go                                         |
| `package.json` (root `type: module`) | Node / TypeScript — inspect `dependencies` |
| `tsconfig.json`                      | TypeScript                                 |
| `next.config.*`                      | Next.js                                    |
| `svelte.config.*`                    | Svelte (check version in `package.json`)   |
| `vite.config.*`                      | Vite (pair with React or Svelte signal)    |
| `Package.swift` / `*.xcodeproj`      | Swift / iOS                                |
| `build.gradle` / `build.gradle.kts`  | JVM — Java or Kotlin (inspect sources)     |
| `pubspec.yaml`                       | Dart / Flutter                             |
| `*.tf` / `.terraform.lock.hcl`       | Terraform or OpenTofu (check binary in CI) |
| `terragrunt.hcl`                     | Terragrunt on top of Terraform / OpenTofu  |

**Polyglot** (common for monorepos): multiple markers coexist at different
paths — e.g., `crates/` with `Cargo.toml`, `packages/web/` with
`package.json`. Note *where* each stack lives; this drives `paths:`
scoping in Phase 4.

Load the relevant stack references *only*. See `references/stacks/<name>.md`
for each detected stack. Don't load stacks the project doesn't use — it
just adds noise.

### Phase 3 — Extract and classify source rules

Read the source. For each discrete rule or convention, classify it:

- **Universal** — applies to any project regardless of stack. Examples:
  "never commit without explicit permission", "no secrets in git",
  "ask before destructive operations". Copy as-is.
- **Process** — commit, PR, review, release conventions. Usually copies
  cleanly; adjust only if the target's workflow differs (e.g., different
  CI, different branch model).
- **Stack-specific, shared with target** — source and target both use the
  stack. Copy with minor path or command adjustments.
- **Stack-specific, translatable** — the intent is stack-agnostic but the
  command names differ. Example: "lint before commit" → translates
  per-stack via the stack reference. Rewrite the command.
- **Stack-specific, not applicable** — source stack isn't in the target.
  **Skip**, but list skipped items so the user can confirm. Never port a
  rule you can't meaningfully translate.

**Personal vs team**: if a rule is clearly personal (e.g., "I prefer
semicolons"), the target file is `CLAUDE.local.md` (gitignored). If it's
a team norm, target is the shared tree.

### Phase 4 — Organize for the target

The target's rule layout follows load-time semantics (see
`references/loading.md` for the full mechanics — read it if you're unsure
whether a rule will actually load).

**Root `CLAUDE.md` (target 50–100 lines)**: critical rules, project
overview, Do-Not-Add list, entry-point pointers. Cross-cutting content
only.

**`.claude/rules/<topic>.md` (no frontmatter, always-loaded)**: topics the
user might ask about cold. Examples: `architecture.md`, `testing.md`,
`build-release.md`, `commands.md`, `security.md`. Also stack-specific
topics for *single-stack* projects: `rust.md`, `python.md`, etc.

**`.claude/rules/<stack>.md` with `paths:` frontmatter (polyglot only)**:
in a monorepo, each stack's conventions are path-scoped to its subtree.
See the *Polyglot path-scoping* section in each stack reference for the
exact glob pattern.

**`CLAUDE.local.md`**: personal preferences (semicolons, trailing commas,
dark-theme rationales) and anything the user explicitly marks as "just me".

**Never** wire `.claude/rules/*.md` files via `@import` from root — they
auto-discover. `@import` is for files *outside* `.claude/rules/`.

### Phase 5 — Present proposal, then write

Produce a concrete diff-style proposal before touching the filesystem:

```
Will create:
  .claude/rules/rust.md        (45 lines — build, fmt, clippy, test rules)
  .claude/rules/architecture.md (30 lines — ported from <source>)
  .claude/rules/testing.md      (25 lines — ported + translated for cargo test)

Will modify:
  CLAUDE.md (append 'Do NOT Add' section, 6 lines)

Will skip (source rules not applicable to target Rust stack):
  - 'Prefer ESM over CJS' — TypeScript-specific
  - 'Use pnpm, not npm' — Node-specific

Will leave alone (target already has):
  .claude/settings.json (permissions — handled by claude-settings skill)
```

Ask the user to confirm. On confirmation, write. If target has existing
rule files that overlap, *merge* (additive) or show the conflict for the
user to resolve — don't overwrite silently.

After writing, verify with a sanity check. A fresh session + `/memory`
should list every new rule file. If something is missing, the frontmatter
is wrong or the path is off — use the `InstructionsLoaded` hook to
diagnose.

## Classifying rules — examples

When in doubt about classification, ask: *would a competent developer on
a totally different stack still want this rule?*

| Rule                                                    | Class                    | Why                                                |
| ------------------------------------------------------- | ------------------------ | -------------------------------------------------- |
| "Never commit without explicit permission"              | Universal                | Applies to any project                             |
| "All PRs need a design doc for changes over 300 lines"  | Process                  | Team workflow, stack-agnostic                      |
| "Run `pnpm lint && pnpm test` before claiming done"     | Stack-specific, translatable | Translate command per target's stack           |
| "Use `z.infer<typeof schema>` for API input types"      | Stack-specific, TS       | Copy only if target uses TypeScript + Zod          |
| "Prefer `Result<T, E>` over panics in library code"     | Stack-specific, Rust     | Skip entirely for non-Rust targets                 |
| "I like trailing commas"                                | Personal                 | `CLAUDE.local.md` or `~/.claude/CLAUDE.md`          |
| "Use 2-space indent"                                    | Stack-specific (usually) | Most projects pin this per stack via formatter config — prefer encoding in `.editorconfig` or formatter config over rules |

## Stack-aware translation

When a source rule says "run X before commit", the translation is *not*
just swapping tool names — it's knowing the idiomatic pre-commit pipeline
for the target stack. See the per-stack references for exact commands.

Quick pointers (load the reference file before writing anything):

- Rust → `references/stacks/rust.md`
- Python → `references/stacks/python.md`
- Go → `references/stacks/go.md`
- TypeScript (base) → `references/stacks/typescript.md`
- React (layered on TS) → `references/stacks/react.md`
- Next.js (layered on React) → `references/stacks/nextjs.md`
- Svelte 5 → `references/stacks/svelte.md`
- Swift / iOS → `references/stacks/swift.md`
- Kotlin / Android → `references/stacks/kotlin.md`
- Java → `references/stacks/java.md`
- Terraform / OpenTofu → `references/stacks/terraform.md`

If the target uses a stack not listed, tell the user so directly — don't
make up commands.

## Handling conflicts and the target's existing rules

If the target already has `CLAUDE.md` or `.claude/rules/*.md`:

- **Additive merge first**: new sections/files that don't overlap just
  land.
- **Overlap detected**: show both versions side-by-side, ask the user
  which wins or whether to combine.
- **Target has a bloated 400+ line CLAUDE.md**: before porting, consider
  splitting it. See `references/splitting-guide.md` — often the right
  order is (a) split existing content first, (b) then port new rules
  into the now-structured tree.

## Foundations

These references hold mechanical details you'll need mid-workflow. Load
them when the specific question arises — don't load all of them
preemptively.

- `references/loading.md` — every load-time mechanism: tree-walk,
  `.claude/rules/` auto-discovery, `paths:` frontmatter, `@import`,
  subdirectory CLAUDE.md, `CLAUDE.local.md`, managed policy, symlinks,
  `claudeMdExcludes`, `/memory`, `InstructionsLoaded` hook, auto memory.
  Read when wiring anything non-trivial or debugging a rule that "should"
  load.
- `references/splitting-guide.md` — when the target already has a bloated
  CLAUDE.md; recipe for pruning and splitting before porting new rules in.
- `references/templates.md` — starter templates for root `CLAUDE.md`,
  unscoped rules, path-scoped rules, `CLAUDE.local.md`. Use as skeletons
  when Phase 4 lands content.

### Canonical upstream docs

When `references/loading.md` is silent or stale, the authoritative source
is Anthropic's own documentation. Re-fetch these before trusting any claim
in the bundled references that's more than a few months old.

- <https://code.claude.com/docs/en/memory> — main memory / rules doc
- <https://code.claude.com/docs/en/memory#organize-rules-with-claude/rules/> — `.claude/rules/` section
- <https://code.claude.com/docs/en/hooks> — `InstructionsLoaded` hook for debugging what loaded
- <https://code.claude.com/docs/en/settings> — `claudeMdExcludes` and related config fields

The bundled references quote the relevant passages verbatim so the skill
still works offline, but the upstream URLs are the tiebreaker when the
docs evolve.

## Anti-patterns

- **Copying source rules verbatim across stacks.** If the source says
  `pnpm lint` and the target is Rust, the rule needs to become
  `cargo clippy --all-targets -- -D warnings`. Verbatim carry is the
  most common failure mode.
- **Using Cursor-style frontmatter** (`globs`, `alwaysApply`). Claude
  Code only recognises `paths:`. Other fields are silently ignored —
  a rule that looks scoped may load unconditionally, or vice versa.
- **Wiring `.claude/rules/` files via `@import` from root.** They
  auto-discover; the `@import` is pure maintenance debt.
- **Overwriting target's existing rules.** Always merge or show the
  conflict. Destructive writes have bitten users enough that the default
  must be additive.
- **Dumping all of the source's conventions without classification.**
  Stack-specific rules for the wrong stack don't just waste tokens, they
  mislead Claude in the target.
- **Path-scoping rules the user asks about in the abstract.** A rule
  scoped to `src/api/**` won't load when the user asks "how do we handle
  errors in this project?" without opening an API file first. Default to
  unscoped for topics asked cold; scope only polyglot per-stack splits
  and truly subtree-local rules.

## Writing style for output rule files

Terse, concrete, one idea per bullet. Explain *why* when the rule isn't
obvious — "validate request IP because L6 of the threat model forbids
attacker-controlled inputs" beats "validate request IP". Include a
one-line `Applies to:` signpost at the top of each rule file so humans
browsing the repo know the scope at a glance.

The smoke test for every written file: a contributor unfamiliar with the
project should be able to read it in under two minutes and know what to do
differently tomorrow. If they can't, tighten.
