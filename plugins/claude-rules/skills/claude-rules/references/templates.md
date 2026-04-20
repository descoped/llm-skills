# Rule-file templates

Opinionated starting points. Adapt topic names and content to the project;
keep the shape.

## Root `.claude/CLAUDE.md`

Target: 50–100 lines. Cross-cutting content only. No `@import` block needed
for `.claude/rules/` files — they auto-discover.

```markdown
# CLAUDE.md

Guidance for Claude Code when working with <project>.

## CRITICAL RULES

**NEVER COMMIT WITHOUT EXPLICIT PERMISSION**
- The developer is the decision-maker; Claude is an assistant.
- Present options; let the user choose.
- If in doubt, ASK before making changes.

## Project Overview

<one-paragraph what-and-why>

Repository: <url>

## Development Principles

- <principle 1 — terse, actionable>
- <principle 2>
- <principle 3>

## Do NOT Add Unless Explicitly Asked

- ❌ <scope creep the project has decided against>
- ❌ <another one>

## Entry-point files

- `<path>` — <what it is>
- `<path>` — <what it is>
```

## `.claude/rules/architecture.md` — unscoped, always-loaded

```markdown
# Architecture

Applies to: whole project.

## Core flow

<numbered steps of the happy path>

## Component map

<top-level directories + one-line purpose each>

## Invariants

<cross-cutting rules — security, performance, compatibility>
```

## `.claude/rules/<topic>.md` — unscoped generic shape

```markdown
# <Topic>

Applies to: whole project.

## <section>

<rules — concrete, verifiable, one idea per bullet>

## Gotchas

<surprising-but-real pitfalls the reader should know>
```

## `.claude/rules/<topic>.md` — path-scoped

```markdown
---
paths:
  - "<subtree>/**"
  - "<specific-file-or-glob>"
---

# <Topic>

Applies to: `<subtree>`.

## <section>

<rules that only matter when working inside the named subtree>

## Why this is scoped

<one-line reason the rule doesn't need to load for general conversation>
```

## `CLAUDE.local.md` — personal per-project notes (gitignored)

```markdown
# Local notes

- Preferred test data: <path>
- Sandbox URL: <url>
- Per-env tweaks: <...>
```

Add `CLAUDE.local.md` to `.gitignore`.

## Smoke test for every rule file

A contributor unfamiliar with the project should be able to read the file
in under two minutes and know what to do differently tomorrow. If they
can't, tighten the rules.
