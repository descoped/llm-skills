# Customizing `statusline.sh`

Read this file when the user asks to change colors, thresholds, path-compression budget, or which segments appear — anything beyond the initial install. The main `SKILL.md` workflow stops at "install + verify"; everything here is post-install tweaking.

## Path width budget

By default the rendered path adapts to `$COLUMNS`:

| Terminal width | Max path chars |
|---|---|
| ≥ 180 | 48 |
| ≥ 140 | 36 |
| ≥ 100 | 26 |
| < 100 | 18 |

Override with the `SL_PATH_MAX` env var (set in the user's shell init or in Claude Code's env config):

```bash
export SL_PATH_MAX=40
```

Why: `$COLUMNS` isn't always propagated to subprocesses, and some users prefer a fixed budget regardless of terminal width.

### Compression tiers (for reference)

When the rendered path would exceed the budget, it collapses in four tiers:

| Tier | Example |
|---|---|
| full | `~/Code/krantho/packages/admin` |
| drop middle, keep 2 | `~/../packages/admin` |
| drop middle, keep leaf | `~/../admin` |
| truncate leaf | `~/../…ckages/admin` |

`..` marks hidden path segments; `…` marks a truncated leaf. They're visually distinct so the user can't confuse "we hid directories" with "we cut off characters".

## Colors

All colors are ANSI escapes declared as `readonly` constants at the top of the script:

```bash
readonly BOLD=$'\033[1m'
readonly GREEN=$'\033[32m'
readonly CYAN=$'\033[36m'
readonly MAGENTA=$'\033[35m'
readonly YELLOW=$'\033[33m'
readonly RED=$'\033[31m'
readonly DIM=$'\033[38;5;245m'
```

Change a segment's color by editing the `printf` / string concatenation that uses the color variable — not the constant itself (that would cascade unwanted changes).

| Segment | Color variable used |
|---|---|
| Project | `BOLD` + `GREEN` |
| Path | `DIM` |
| Branch (⎇) | `MAGENTA` |
| Dirty flags `[?!+x]` | `YELLOW` |
| Model | `CYAN` |
| Thinking `[think:*]` | `YELLOW` |
| Context bar | `GREEN`/`YELLOW`/`RED` (picked by `ctx_color`) |
| Cost | `DIM` |
| Separator `│` | `DIM` |

## Adding or removing segments

The script builds two halves near the bottom:

- `left` — project, path, branch, model
- `right` — context bar, tokens, cost

Each segment is appended to `left+=…` or `right+=…`, always guarded by an availability check (`[[ -n "$branch" ]]`, `[[ -n "$ctx_pct" ]]`, etc.). To remove a segment, delete the corresponding appending block — the guards mean neighbors keep working.

Common edits:

- **Drop cost**: delete the `if [[ -n "$cost_usd" ]] …` block at the bottom
- **Drop tokens**: trim the `right+=…↑↓…` line, keeping the `right=…bar pct…` line above
- **Drop path**: delete the `[[ "$(dirname "$short_path")" != "." ]] && left+=…` line
- **Drop thinking indicator**: delete the `case "$thinking" in … esac` block before `left+="${SEP}${model_display}"`

## Adjusting context-usage color thresholds

Edit `ctx_color`:

```bash
ctx_color() {
    local pct="${1%.*}"
    pct=${pct:-0}
    if   (( pct >= 80 )); then printf "%s" "$RED"
    elif (( pct >= 50 )); then printf "%s" "$YELLOW"
    else                       printf "%s" "$GREEN"
    fi
}
```

Tighten or loosen the thresholds to taste. Values are percentages (0-100).

## Testing changes standalone

Before trusting the change in a live Claude Code session, render the script against a sample JSON payload:

```bash
echo '{
  "workspace": {"current_dir": "/Users/me/Code/app"},
  "model": {"display_name": "Claude Opus 4.7 (1M context)", "id": "claude-opus-4-7[1m]"},
  "context_window": {"used_percentage": 42, "total_input_tokens": 450000, "total_output_tokens": 85000},
  "cost": {"total_cost_usd": 2.145}
}' | bash ~/.claude/statusline.sh
```

The output is a single colored line on stdout. If you see only ANSI escape codes with no visible text, the terminal isn't interpreting colors — try piping through `cat -v` to inspect the raw bytes, or test in a different terminal.

Vary the JSON fields to exercise edge cases: high `used_percentage` for red bar, large `total_input_tokens` for `M` formatting, missing `cost` field for cost-segment omission.
