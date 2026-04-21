---
name: session-snapshot
description: >
  Save and restore Claude Code session state across `/compact` boundaries. Use when the user
  is about to run `/compact`, has just run `/compact`, says "we need to compact", "save the
  session", "restore the session", "before we compact write the state", "context is getting
  full", "dump the plan before we compress", "I compacted, catch up", or otherwise signals
  that they want durable handoff notes that survive conversation compression. Also trigger
  on explicit invocations like `/session-snapshot save`, `/session-snapshot restore`, or
  `/session-snapshot list`. The skill writes a dated markdown file to `.claude/session-state/`
  before compact and reads + deletes the most recent file after compact, rehydrating the
  working context so the next turn resumes with full intent, decisions, and the next-step
  sequence intact. On restore, the skill re-anchors on `~/.claude/CLAUDE.md`, the project's
  `CLAUDE.md`, and `.claude/rules/` before the snapshot's next step is acted on, so post-compact
  work stays consistent with the user's conventions instead of drifting into whatever the
  snapshot happened to name first.
---

# Session Snapshot

Two verbs — **save** before `/compact`, **restore** after. The snapshot lives in `.claude/session-state/` (project-local, gitignored, ephemeral). It captures intent, locked-in decisions, work-in-progress, and a concrete next-step sequence so the next turn of the conversation resumes cleanly even though Claude's summary of the prior turns is lossy.

## When this skill triggers

- `save`: user says "we need to compact", "before we compact write the state", "context is full", "dump the plan", "save the session", or explicitly `/session-snapshot save`.
- `restore`: the conversation just compacted and the user says "catch up", "restore", "pick up where we left off", "read the handoff", or explicitly `/session-snapshot restore`.
- `list`: user wants to see existing snapshots — `/session-snapshot list`.

If the argument is ambiguous, look at `.claude/session-state/`. If the directory has a recent file and the conversation looks freshly compacted (short history, system summary mentions prior session), lean `restore`. Otherwise lean `save`.

## Directory layout

```
<project-root>/
└── .claude/
    └── session-state/
        └── YYYYMMDDTHHMMZ_session-state.md
```

- **Project-local**, not global — each project has its own snapshots. Different repos, different handoffs.
- **`.claude/session-state/`** (singular `session`) — picked to avoid collision with Claude Code's home-dir `~/.claude/sessions/` (which stores JSONL session logs) and `~/.claude/session-env/` (which stores environment snapshots). As of Claude Code's current layout, project-level `.claude/session-state/` is unclaimed.
- **Gitignored.** These files capture mid-task thought-state and often brush against environment specifics (paths, branch names, partial commands). Treat them as ephemeral.
- **UTC filename prefix** (`YYYYMMDDTHHMMZ`) matches the convention used by long-lived design docs in projects like `ai_docs/`. Sort by filename = sort by time.

### First-run setup

On the first `save` in a project, before writing the file:

1. Create `.claude/session-state/` if missing.
2. Ensure `.gitignore` contains `.claude/session-state/`. If `.gitignore` doesn't mention it, append:
   ```
   # Ephemeral Claude Code session handoffs (see llm-skills/session-snapshot)
   .claude/session-state/
   ```
3. If the project's root is not a git repo, skip step 2 silently — the directory just exists as local scratch.

Don't prompt the user for any of this. It's one-shot setup that should feel invisible.

---

## `save` — write a snapshot before `/compact`

The goal is to produce a single markdown file that, read cold by a future Claude instance with no prior context, contains enough to resume work without re-asking the user basic questions.

### Step 1 — Gather the state from the current conversation

Work through these prompts mentally (or visibly if the user wants to see it):

- **What is the user trying to do right now?** One sentence. The active goal, not the project's general purpose.
- **What has been decided?** List the calls that shouldn't be re-litigated — design choices, naming, scope cuts, architecture picks.
- **What's in flight?** Files being edited, commits staged but unpushed, tests partially written, plans drafted.
- **What's the next-step sequence?** A numbered list of concrete actions. Each step should be independently reviewable. "Do step 1, then step 2" beats "do the thing".
- **What's blocked on the user?** Open questions where Claude cannot proceed without a decision.
- **Which files / symbols matter?** File paths with line numbers or function names for the code regions most relevant to resume work. Don't dump full files — name the anchors.
- **How should the next turn literally start?** The first command to run or file to read after restore.

If the current conversation has a plan (from `ExitPlanMode`, a `Plan` agent, or a `TaskList`), capture its current state — not a summary, the actual items with their status.

### Step 2 — Apply the privacy guardrail

**Never include** any of these in a snapshot file, even under "the user said commit all":

- IP addresses (except RFC 5737: `192.0.2.x`, `198.51.100.x`, `203.0.113.x`)
- Hostnames / FQDNs (except RFC 2606: `example.com`, `example.net`, `*.invalid`, `*.localhost`)
- AWS account IDs, customer resource IDs, zone IDs, subscription IDs
- MAC addresses, device serials, UDID, hardware IDs
- Credentials, tokens, API keys, basic-auth strings — ever, in any form
- Local usernames other than `$USER` / `$HOME` placeholder form
- File paths that embed identifying info (absolute paths under `/Users/<name>/…` are fine; paths under `/data/<customer>/…` are not)

If the snapshot *has* to reference one of the above to be useful, replace it with a placeholder and a recovery hint: `<WAN IP — read from config.secure>`, `<zone ID — in AWS console under Route53>`. The handoff must be usable without being a data leak.

Before writing, re-read what you've drafted with fresh eyes, scanning specifically for these leaks. This matters even with gitignore in place — gitignores get edited, directories get shared.

### Step 3 — Write the file

Filename: `YYYYMMDDTHHMMZ_session-state.md` where the timestamp is the current UTC moment (`date -u +%Y%m%dT%H%MZ`). Use the `Write` tool.

Apply this template:

```markdown
# Session state — <one-line title, e.g., "pre-compact, v0.3.0 Lambda work not started">

**Captured:** <YYYY-MM-DD HH:MM UTC>
**Branch:** <branch> at <short SHA>
**Working tree:** <clean | N uncommitted files — list them>

## Active goal

<one or two sentences — what is in progress right now>

## Locked-in decisions

<bulleted list of calls that are settled — don't relitigate>
- Decision: Reason.
- Decision: Reason.

## Work in progress

<what's partially done — files, edits, commits, tests>

## Next-step sequence

1. Concrete first action (one commit of work).
2. Concrete second action.
3. …

## Open questions (blocked on user)

<bulleted list — empty if nothing is blocked>

## Key anchors

<file:line or path references the next session will want>
- `path/to/file.go:45` — function Foo, being refactored.
- `docs/plan.md` — design doc, section "Wave 2".

## How to resume

1. First command to run after restore (e.g., `git status`, `just test`).
2. First file to re-read.
3. What to tell the user to confirm before continuing.

## Privacy self-check

- [x] No IPs, hostnames, account IDs, credentials, or device identifiers in this file.
- [x] Placeholders used where recovery is possible.
```

After writing, tell the user exactly one sentence: "Saved `.claude/session-state/<filename>`. Safe to run `/compact` now — I'll restore from it after."

### Step 4 — Don't auto-trigger compact

The skill writes the snapshot; the user runs `/compact`. Don't chain them — the user may want to review the file first, or may have decided not to compact after all.

---

## `restore` — read and delete the most recent snapshot

### Step 1 — Find the file

List `.claude/session-state/*.md`. If empty, tell the user "No snapshot found in `.claude/session-state/` — nothing to restore." and stop.

If multiple files exist, pick the one with the newest timestamp prefix (highest-sorting filename). Mention if there are older files; leave them alone unless the user asks to clean up.

### Step 2 — Read the snapshot file

Use the `Read` tool on the file. Hold what it says — don't summarize to the user yet; the summary waits until after Step 3 so it can flag any rule conflicts surfaced during refresh.

### Step 3 — Refresh memory before anything else

`/compact` preserves the CLAUDE.md files in the system prompt, but the model's working attention has been truncated — rules and user conventions that felt salient before compact often don't get re-consulted post-compact, and the next action drifts into whatever the snapshot happened to name first. Restore is the moment to re-anchor. Do this **before** interpreting the snapshot's next-step sequence and **before** any tool call that isn't a Read.

Load in this order:

1. **User global memory** — `Read ~/.claude/CLAUDE.md`. If it contains `@import` references, follow one hop (the docs allow up to 5; one is enough for sanity).
2. **Project root CLAUDE.md** — `Read <project-root>/CLAUDE.md` if it exists. Also read `CLAUDE.local.md` if present.
3. **Nested CLAUDE.md** — if the snapshot's "Key anchors" point into a subdirectory, `Read` the nearest `CLAUDE.md` up the tree from that anchor (skip if it's the root file already read).
4. **`.claude/rules/`** — `Glob .claude/rules/**/*.md`. `Read` each. For rules with `paths:` frontmatter, mentally scope them to the globs they declare — they apply only when the next-step sequence touches matching files. Rules without `paths:` apply unconditionally.
5. **Auto-memory index** — if `~/.claude/projects/<project>/memory/MEMORY.md` exists, `Read` it. Don't preload every individual memory file; the index is enough to know what's available.

Then, with the snapshot and rules both in working context, cross-check:

- Does the snapshot's "Next-step sequence" violate any rule? (e.g., snapshot says "add a comment explaining the fix" but a rule says "default to no comments").
- Does any rule's tooling (build, test, lint command) differ from what the snapshot's "How to resume" proposes? If yes, the rule wins.
- Are there any `feedback` memories in the auto-memory index that contradict the snapshot's plan?

If a conflict exists, flag it in the Step 4 summary so the user can adjudicate before work resumes.

### Step 4 — Summarize to the user

In your own words, tell them in 3–5 lines:

- What the active goal was.
- What's the very next thing to do.
- Whether there are open questions blocking progress.
- **Any conflicts found in Step 3** between the snapshot's plan and the project/user rules — one line per conflict, naming the rule file.

Don't dump the whole file back to them — they already know the content; this is a handoff check, not a read-aloud. If no conflicts were found, say so explicitly ("Checked against `~/.claude/CLAUDE.md`, project CLAUDE.md, and `.claude/rules/*` — no conflicts.") so the user knows the refresh actually happened.

### Step 5 — Delete the file

After reading and summarizing, delete it. Rationale: snapshots are pre-compact handoffs, not long-term records. If a piece of the snapshot belongs in permanent project memory (e.g., an architectural decision), the conversation that resumes will promote it into `ai_docs/`, a CLAUDE.md, or an auto-memory entry — with proper privacy review. The snapshot file has served its purpose once it's been read.

Use `Bash`: `rm <path>`. Don't ask permission — this is the documented, expected lifecycle. The user already agreed to it by invoking `restore`.

If the user explicitly says "don't delete", use `mv <file> <file>.archived` instead so the next `restore` doesn't pick it up.

### Step 6 — Stop and wait for the user

After restore + memory refresh + delete, **stop**. Do not start executing the snapshot's "How to resume" sequence, and do not pick up any "outstanding" item from "Work in progress" on your own. The user's next turn is where the real work resumes — they may want to redirect based on the Step 4 summary, or they may have new information that changes the plan.

No exceptions for "purely informational" commands. Even a read-only `git status` can burn user attention on output they didn't ask for at this moment; wait until the user speaks.

---

## `list` — show what's in `.claude/session-state/`

Rare — mostly for debugging or cleanup. Show the user:

```
.claude/session-state/
  20260418T1936Z_session-state.md  (2.1 KB, 8 min ago)
  20260415T0802Z_session-state.md.archived  (3.4 KB, 3 days ago)
```

Offer to delete archived files older than N days if there are more than two.

---

## Edge cases

**Project has no `.claude/` directory.** Create it. Don't create it at the home dir — the skill is project-scoped.

**Multiple snapshots from the same day.** Minute-precision in the filename (`YYYYMMDDTHHMMZ`) handles this. If truly same-minute, append `_2`, `_3`.

**`save` called but nothing meaningful has happened.** Still write the file — the user asked for it, and an empty-ish snapshot is a legitimate checkpoint. Don't second-guess.

**`restore` called but the conversation clearly has full prior context.** The user may be re-checking. Read the file, give the 3–5-line summary, and ask "I read the snapshot — does anything conflict with what we already know?" before deleting.

**Project is a worktree.** `.claude/session-state/` lives in the worktree, not the primary repo. Treat each worktree as its own project for this purpose.

**Non-git project.** Skip the `.gitignore` setup step. Files still go in `.claude/session-state/` locally.

**Privacy leak noticed during restore.** If reading the file reveals something that shouldn't be in there (an IP slipped through, a token got captured), delete the file immediately, tell the user what was in it in general terms, and suggest they update the save flow for next time. Don't quote the leaked content back at them.

---

## Why this skill exists

Claude Code's `/compact` replaces conversation history with a model-generated summary. The summary is strong on "what happened" but weak on "what's decided, what's next, what's blocked, what not to re-argue". In long sessions — multi-day feature work, release prep, architecture exploration — the lossy summary becomes the bottleneck: the next turn starts by re-asking questions already settled, or by re-deriving conclusions already reached.

A session snapshot shifts the load: before compact, Claude + user jointly produce a terse, high-signal handoff doc. After compact, Claude reads it, re-anchors on the user's and project's governing rules, and only then resumes. The doc is ephemeral by design (gitignored, deleted on restore) because its value is bounded to one compact boundary — promoting durable insights to `ai_docs/`, CLAUDE.md, or auto-memory is a separate, explicit step with its own privacy review.

The mandatory memory refresh on restore exists because a snapshot, by itself, is a description of *what* to do next — not a description of *how this user and project want things done*. Those "how" constraints live in `~/.claude/CLAUDE.md`, the project's `CLAUDE.md`, and `.claude/rules/`, and they survive `/compact` in the system prompt but not necessarily in Claude's working attention. Re-reading them at restore keeps the next action consistent with the user's conventions instead of drifting into whatever approach the compacted summary most recently emphasized.

The privacy guardrail in `save` isn't decoration — without it, snapshots become a new channel for environment data to leak (into gitignored files that someone later un-gitignores, into `/tmp` copies, into pastes for debugging). Treat the snapshot file like a commit: nothing goes in that you wouldn't be comfortable with a colleague reading cold.
