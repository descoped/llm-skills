---
name: statusline
description: >
  Install or replace the Claude Code status line — a compact prompt bar showing the current
  project, auto-compressed path, git branch with dirty-state flags, model name with context
  window and thinking level, live context-usage bar, token counts, and session cost. Use when
  the user wants to install, replace, fix, or upgrade their Claude Code status line, make the
  Claude Code prompt bar show git branch or dirty state, see which model they're running
  ("what model am I on"), see token burn or context percentage in the bottom bar, or
  customize colors/segments of the status line. Also trigger when the user says their status
  bar is broken, missing, ugly, or they want a better Claude Code prompt.
---

# Claude Code Status Line

Install a compact, informative status line for Claude Code. The script is self-contained — no hardcoded paths, no user-specific assumptions — so it's safe to install on any system.

## What It Shows

```
krantho  ~/Code/krantho  ⎇ master [?!+]  │  opus-4-7[1m] [think:max]  │  ███░░░░░ 42%  │  ↑450k ↓85k  │  $2.145
```

| Segment | What | Behavior |
|---|---|---|
| `krantho` | Project (bold green) | `basename` of the current dir |
| `~/Code/krantho` | Path (dim) | `$HOME` → `~`; auto-compressed when too long |
| `⎇ master` | Git branch (magenta) | Omitted if not in a repo; falls back to short SHA on detached HEAD |
| `[?!+x]` | Dirty-state flags (yellow) | `?` untracked, `!` modified, `+` staged, `x` deleted |
| `opus-4-7[1m]` | Model (cyan) | `claude-` stripped; `[1m]` / `[200k]` is context window |
| `[think:max]` | Thinking level (yellow) | Shown only when the thinking variant is active |
| `███░░░░░ 42%` | Context usage bar | Green <50%, yellow <80%, red ≥80% |
| `↑450k ↓85k` | Tokens in/out | Human-formatted (`k`, `M`) |
| `$2.145` | Session cost | Shown only when cost is reported |

Path compression kicks in when the rendered path would overflow the terminal — four tiers from full path down to `~/../…truncated`. See `references/customization.md` if the user wants to tune the width budget.

## Installation Workflow

When the user asks to install the status line, work through these phases in order.

### Phase 1 — Confirm scope

Ask whether the user wants the status line installed:

- **Globally** (applies to every Claude Code session) → install to `~/.claude/`
- **Per project** (scoped to a single repo) → install to `<repo>/.claude/`

Default to global unless the user specifies project-scope — global is the common case.

### Phase 2 — Copy the script

**Step 1 — Back up any existing `statusline.sh`.** Users often have a custom status line they'll want to revert to. Skip this step if no existing file is found.

```bash
# Global install
if [ -f ~/.claude/statusline.sh ]; then
  cp ~/.claude/statusline.sh ~/.claude/statusline.sh.bak.$(date +%Y%m%d-%H%M%S)
  echo "Backed up to: ~/.claude/statusline.sh.bak.$(date +%Y%m%d-%H%M%S)"
fi

# Project install
if [ -f .claude/statusline.sh ]; then
  cp .claude/statusline.sh .claude/statusline.sh.bak.$(date +%Y%m%d-%H%M%S)
  echo "Backed up to: .claude/statusline.sh.bak.$(date +%Y%m%d-%H%M%S)"
fi
```

Tell the user the exact backup path so they know how to restore.

**Step 2 — Copy `assets/statusline.sh`** from this skill to the chosen location:

- Global: `~/.claude/statusline.sh`
- Project: `<repo>/.claude/statusline.sh`

**Step 3 — Make it executable:**

```bash
chmod +x ~/.claude/statusline.sh
```

### Phase 3 — Register it in settings.json

**Step 1 — Back up existing `settings.json`** before the `jq` merge. The merge is safe in principle, but a `jq` failure mid-pipe or a user who wants to revert the `statusLine` key needs a safety net.

```bash
# Global
if [ -f ~/.claude/settings.json ]; then
  cp ~/.claude/settings.json ~/.claude/settings.json.bak.$(date +%Y%m%d-%H%M%S)
  echo "Backed up to: ~/.claude/settings.json.bak.$(date +%Y%m%d-%H%M%S)"
fi

# Project
if [ -f .claude/settings.json ]; then
  cp .claude/settings.json .claude/settings.json.bak.$(date +%Y%m%d-%H%M%S)
  echo "Backed up to: .claude/settings.json.bak.$(date +%Y%m%d-%H%M%S)"
fi
```

**Step 2 — Register the `statusLine` key.** Claude Code reads it from `settings.json`. For a global install:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline.sh",
    "padding": 0
  }
}
```

For a project install, use the project-relative path:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash .claude/statusline.sh",
    "padding": 0
  }
}
```

**Step 3 — Merge the key with `jq` — never overwrite the whole file.** Users accumulate permissions, hooks, and plugin config in `settings.json`; a blind overwrite wipes it all out.

```bash
jq '. + {statusLine: {type: "command", command: "bash ~/.claude/statusline.sh", padding: 0}}' \
  ~/.claude/settings.json > ~/.claude/settings.json.new \
  && mv ~/.claude/settings.json.new ~/.claude/settings.json
```

If `settings.json` doesn't exist, create it with just the `statusLine` key.

### Phase 4 — Verify

Render the script against a sample payload to confirm it produces output:

```bash
echo '{"workspace":{"current_dir":"'"$PWD"'"},"model":{"display_name":"Claude Opus 4.7 (1M context)","id":"claude-opus-4-7"},"context_window":{"used_percentage":10}}' \
  | bash ~/.claude/statusline.sh
```

The user should see a colored status line. If they see `statusline: jq not found` on stderr, `jq` isn't installed — stop here and tell them (see Dependencies below).

Tell the user to **restart Claude Code or open a new session** for the status line to take effect. Running sessions don't pick up the new `settings.json` until reload.

## Dependencies

| Tool | Required? | What happens if missing |
|---|---|---|
| `bash` 3.2+ | Required | Script is bash-only |
| `jq` | Required | Prints `statusline: jq not found` to stderr, exits cleanly |
| `git` | Optional | Branch/dirty segment omitted (other segments still render) |
| `tput` | Optional | Falls back to assumed 100-column width |

If `jq` is missing, tell the user to install it before continuing:

- macOS: `brew install jq`
- Debian/Ubuntu: `sudo apt install jq`
- Fedora/RHEL: `sudo dnf install jq`
- Arch: `sudo pacman -S jq`

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Empty status line | `jq` not installed | Install `jq` (see Dependencies) |
| No colors | Terminal doesn't support ANSI | Upgrade terminal, or strip color variables (set them to empty) |
| Branch missing | `cwd` not a git repo, OR git is missing | Expected for non-repo dirs; install git if in a repo |
| `⎇` renders as `?` or boxes | Terminal font missing the glyph | Use a Unicode-aware font (any modern terminal font) |
| Path still overflows | `$COLUMNS` not propagated to script env | Set `SL_PATH_MAX` explicitly (see `references/customization.md`) |
| Script exits with error | Likely bash < 3.2 | Upgrade bash, or install via `brew install bash` on older macOS |

## Customization

For post-install tweaks — colors, path width, which segments appear, context-bar thresholds — read `references/customization.md`. Don't modify the script preemptively; wait for the user to ask.
