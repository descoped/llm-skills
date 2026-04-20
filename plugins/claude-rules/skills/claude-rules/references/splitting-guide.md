# Splitting a flat CLAUDE.md

A flat `CLAUDE.md` is fine until it isn't. This file walks through the
refactor — when to split, how to split, and how to verify nothing broke.

## Before you split — try pruning

Most flat CLAUDE.md files carry 20–30% redundancy. Before restructuring,
reclaim that first:

- **Delete "Current Status" / "Completed Features" sections.** Write-only;
  nobody updates them after shipping. `git log` is authoritative.
- **Collapse duplicates.** "Development Guidelines" and "Development
  Principles" often drift into the same content — merge them.
- **Remove restated code.** Replace snippets with `path/to/file.go:45`
  references. Copied code rots; line references stay honest.
- **Cut padding.** Any sentence that justifies the rule at length instead
  of stating it — move the justification to a linked design doc and leave
  the rule as a single sentence.

Reassess size after pruning. Many files that looked "too long" are actually
well-organised — just stale.

## Signals to split

- File is over ~200 lines *after* pruning. Instruction adherence degrades
  past this threshold.
- Distinct sections are rarely touched together (e.g., deployment vs. CLI
  reference).
- Multiple contributors hit edit conflicts on the same file.
- You can't scan to a specific rule in under ~15 seconds.

## Signals that splitting is premature

- File is under ~150 lines and well-organised.
- All rules are genuinely cross-cutting — splitting would just scatter them.
- Low contributor count, low edit frequency.

## The refactoring recipe

Do this on a feature branch so the diff is reviewable.

### Step 1 — Inventory and group

Read the flat file end-to-end. For each section, decide which bucket it
falls in:

- **Cross-cutting** (stays in root `CLAUDE.md`): critical rules, project
  overview, Do-Not-Add list, core architecture, project-wide conventions,
  entry-point file pointers.
- **Topic-scoped but asked about freely** (`.claude/rules/<topic>.md`,
  no frontmatter): build/release, test philosophy, architecture overview,
  CLI commands.
- **Truly path-scoped** (`.claude/rules/<topic>.md` with `paths:`):
  deployment-specific rules, platform-specific workarounds, vendored
  subproject conventions that *only* matter when working in that subtree.

Typical topic names:

- `architecture.md` — core flow, component map, cross-cutting invariants
- `commands.md` — CLI surface, installer flags
- `platform.md` — per-OS paths and config formats
- `build-release.md` — build commands, test suite shape, release process
- `<deployment-form>.md` — per deployment target, usually `paths:`-scoped

Don't force a split you don't need. If there's one deployment target, don't
invent separate files for it.

### Step 2 — Write the rule files first

For each topic, create `.claude/rules/<topic>.md`:

1. Include `paths:` frontmatter **only** when the rule is genuinely
   path-scoped and the user won't ask about it in isolation. Otherwise
   omit frontmatter — the file loads at launch via auto-discovery.
2. Open with a one-line `Applies to:` signpost for humans reading the repo.
3. State concrete, verifiable rules. "Lambda IAM scoped to one zone,
   UPSERT-only" ✓ — "Write secure infrastructure" ✗.
4. Reference code anchors (`path/to/file.go:45`) instead of restating
   code.
5. Keep each file under ~100 lines. If it grows past that, split again.

### Step 3 — Rewrite root `CLAUDE.md`

Target size: **50–100 lines**. Root holds only cross-cutting content.
Auto-discovery handles the rest — you do **not** need `@import` blocks to
pull in `.claude/rules/*.md`.

Typical root structure:

```markdown
# CLAUDE.md

## CRITICAL RULES
...
## Project Overview
...
## Development Principles
...
## Do NOT Add Unless Explicitly Asked
...
## Entry-point files
...
```

If you want an index for human readers, add one as plain prose (no
`@import`):

```markdown
## Rules index

Topic-scoped rules under `.claude/rules/` — auto-discovered by Claude Code.
Edit the topic files directly; this index is for humans browsing the repo.

- `architecture.md` — core flow, component map, invariants
- `commands.md` — CLI surface + installer flags
- `platform.md` — per-OS paths and config formats
- `build-release.md` — build, test, release process
```

Only use `@import` if you need to reach a file *outside* `.claude/rules/`
or force a specific load order.

### Step 4 — Verify nothing was lost

Run `git diff main..HEAD -- .claude/` and scan section by section. Every
line removed from root should be accounted for in:

- A rule file under `.claude/rules/`
- A deliberate deletion (duplicate, stale content)
- A rephrasing you can point at

If a line is unaccounted for, add it back — don't lose content by accident.

### Step 5 — Sanity check the load

Open a fresh Claude Code session and:

1. Run `/memory`. Every new rule file should appear in the list of loaded
   instruction files (unless it's `paths:`-scoped).
2. Ask a question whose answer lives in an unscoped rule file, **without**
   opening any associated code file. Correct answer ⇒ auto-discovery
   works.
3. Ask a question whose answer lives in a `paths:`-scoped rule file, and
   open a matching code file first. Correct answer ⇒ scope is wired.

If a rule is silently missing, use the `InstructionsLoaded` hook to log
which files loaded and why — the fastest way to find a typo'd path or a
frontmatter bug.

## After the split — keep it healthy

- Edit rules in the same PR as the behavioral change. An out-of-date rule
  is a review blocker, not a follow-up.
- When code moves, update `paths:` globs in the same PR. A stale glob is
  a silent no-op.
- Dedup on touch: when you edit a rule file, skim root `CLAUDE.md` for
  duplicates. Having the same rule in two places guarantees drift.
- Prune quarterly. Any section that has stopped matching reality is a
  delete candidate.
