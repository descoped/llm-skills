#!/usr/bin/env bash
# Claude Code custom status line
# Layout: project  path  ⎇ branch [dirty]  │  model [think]  │  ctx-bar pct  │  tokens  │  cost
#
# Dependencies:
#   jq      — required (JSON parsing)
#   git     — optional (omitted cleanly when not in a repo)
#   tput    — optional (falls back to default width when absent)
#
# Environment overrides:
#   SL_PATH_MAX   — cap rendered path length (default derived from $COLUMNS)
#
# Reads Claude Code status JSON on stdin. Writes one colored line on stdout.
# Self-contained: no hardcoded paths, no user-specific assumptions.

set -euo pipefail

# ── Colors ────────────────────────────────────────────────────────────────────
readonly BOLD=$'\033[1m'
readonly GREEN=$'\033[32m'
readonly CYAN=$'\033[36m'
readonly MAGENTA=$'\033[35m'
readonly YELLOW=$'\033[33m'
readonly RED=$'\033[31m'
readonly DIM=$'\033[38;5;245m'
readonly RESET=$'\033[0m'
readonly SEP="${DIM} │ ${RESET}"

# ── Input ─────────────────────────────────────────────────────────────────────
if ! command -v jq >/dev/null 2>&1; then
    printf "%sstatusline: jq not found%s\n" "$RED" "$RESET" >&2
    exit 0
fi

# Single jq invocation, tab-separated output
IFS=$'\t' read -r cwd model_name model_id ctx_pct tokens_in tokens_out cost_usd \
    < <(jq -r '[
        (.workspace.current_dir // .cwd // ""),
        (.model.display_name     // ""),
        (.model.id               // ""),
        (.context_window.used_percentage     // ""),
        (.context_window.total_input_tokens  // ""),
        (.context_window.total_output_tokens // ""),
        (.cost.total_cost_usd    // "")
    ] | @tsv')

# ── Helpers ───────────────────────────────────────────────────────────────────

# fmt_tokens 1234567 → 1.2M; 12000 → 12k; 999 → 999. Pure bash arithmetic (no bc).
fmt_tokens() {
    local n="${1:-0}"
    [[ "$n" =~ ^[0-9]+$ ]] || { printf "0"; return; }
    if   (( n >= 1000000 )); then printf "%d.%dM" "$((n / 1000000))" "$((n % 1000000 / 100000))"
    elif (( n >= 1000    )); then printf "%dk"    "$((n / 1000))"
    else                          printf "%d"     "$n"
    fi
}

# format_model "claude-opus-4-7[1m]" "Claude Opus 4.7 (1M context)" → "opus-4-7[1m]"
format_model() {
    local id="$1" name="$2" base="" tag=""

    # Strip "claude-" prefix
    base="${id#claude-}"

    # Remove thinking-level markers — they're shown separately as [think:*]
    base="${base//-thinking-max/}"
    base="${base//-thinking-xlarge/}"
    base="${base//-thinking/}"
    base="${base//:thinking-max/}"
    base="${base//:thinking-xlarge/}"
    base="${base//:thinking/}"

    # Extract bracketed suffix already in id, e.g. [1m]
    if [[ "$base" =~ ^(.*)(\[[^]]+\])(.*)$ ]]; then
        base="${BASH_REMATCH[1]}${BASH_REMATCH[3]}"
        tag="${BASH_REMATCH[2]}"
    fi

    # Fallback: derive tag from display name's "(1M context)" suffix
    if [[ -z "$tag" && "$name" =~ \(([0-9]+[KkMm])[^\)]*[Cc]ontext\) ]]; then
        local ctx="${BASH_REMATCH[1]}"
        ctx="${ctx//K/k}"
        ctx="${ctx//M/m}"
        tag="[$ctx]"
    fi

    # Fallback: derive base from display name when id was empty
    if [[ -z "$base" && -n "$name" ]]; then
        base="${name#Claude }"
        base="${base% (*}"
        base=$(printf "%s" "$base" | tr '[:upper:] ' '[:lower:]-')
    fi

    printf "%s%s" "$base" "$tag"
}

# thinking_level → "max" | "xlarge" | "on" | ""
thinking_level() {
    local id="$1" name="$2"
    case "$id" in
        *thinking-max*|*:thinking-max*)       printf "max";    return ;;
        *thinking-xlarge*|*:thinking-xlarge*) printf "xlarge"; return ;;
        *thinking*)                           printf "on";     return ;;
    esac
    case "$name" in
        *[Tt]hinking*[Mm]ax*)    printf "max";    return ;;
        *[Tt]hinking*[Xx]large*) printf "xlarge"; return ;;
        *[Tt]hinking*)           printf "on";     return ;;
    esac
}

# smart_path — progressively compress long paths using `..` (hidden segments)
# and `…` (truncated leaf) so the status line never overflows.
#
# Compression tiers:
#   1. full path               ~/Code/krantho/packages/admin
#   2. drop middle, keep 2     ~/../packages/admin
#   3. drop middle, keep leaf  ~/../admin
#   4. truncate leaf           ~/../…ckages/admin
#
# Budget comes from $COLUMNS (or `tput cols`); override with SL_PATH_MAX.
smart_path() {
    local p="$1"
    # Replace HOME with ~ only when HOME is set and non-empty
    [[ -n "${HOME:-}" ]] && p="${p/#$HOME/~}"

    local cols="${COLUMNS:-}"
    [[ -z "$cols" ]] && cols=$(tput cols 2>/dev/null || printf 100)

    local max
    if   [[ -n "${SL_PATH_MAX:-}" ]]; then max="$SL_PATH_MAX"
    elif (( cols >= 180 ));          then max=48
    elif (( cols >= 140 ));          then max=36
    elif (( cols >= 100 ));          then max=26
    else                                   max=18
    fi

    (( ${#p} <= max )) && { printf "%s" "$p"; return; }

    local prefix rest
    case "$p" in
        \~*) prefix="~/"; rest="${p#\~/}" ;;
        /*)  prefix="/";  rest="${p#/}"   ;;
        *)   prefix="";   rest="$p"       ;;
    esac

    local leaf="${rest##*/}"
    local parent_path="${rest%/*}"
    local parent=""
    [[ "$parent_path" != "$rest" ]] && parent="${parent_path##*/}"

    if [[ -n "$parent" ]]; then
        local two="${prefix}../${parent}/${leaf}"
        (( ${#two} <= max )) && { printf "%s" "$two"; return; }
    fi

    local one="${prefix}../${leaf}"
    (( ${#one} <= max )) && { printf "%s" "$one"; return; }

    local overhead=$(( ${#prefix} + 4 ))   # "../…"
    local keep=$(( max - overhead ))
    (( keep < 4 )) && keep=4
    printf "%s" "${prefix}../…${leaf: -keep}"
}

# ctx_bar — 8-cell Unicode bar, filled proportionally to pct (0-100)
ctx_bar() {
    local pct="${1%.*}"
    pct=${pct:-0}
    (( pct < 0 ))   && pct=0
    (( pct > 100 )) && pct=100
    local filled=$(( (pct * 8 + 50) / 100 ))
    local empty=$(( 8 - filled ))
    local bar=""
    while (( filled-- > 0 )); do bar+="█"; done
    while (( empty--  > 0 )); do bar+="░"; done
    printf "%s" "$bar"
}

# ctx_color — green (<50%), yellow (<80%), red (≥80%)
ctx_color() {
    local pct="${1%.*}"
    pct=${pct:-0}
    if   (( pct >= 80 )); then printf "%s" "$RED"
    elif (( pct >= 50 )); then printf "%s" "$YELLOW"
    else                       printf "%s" "$GREEN"
    fi
}

# build_branch — "⎇ branch [?!+x]" segment, empty if not in a git repo.
# Detached HEAD falls back to short SHA. Single `git status --porcelain` pass.
build_branch() {
    [[ -z "$cwd" ]] && return 0
    git -C "$cwd" --no-optional-locks rev-parse --git-dir >/dev/null 2>&1 || return 0

    local branch
    branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null \
          || git -C "$cwd" --no-optional-locks rev-parse    --short HEAD 2>/dev/null \
          || true)
    [[ -z "$branch" ]] && return 0

    local status dirty=""
    status=$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null || true)
    if [[ -n "$status" ]]; then
        grep -q    "^??"          <<<"$status" && dirty+="?"
        grep -qE   "^[ MARC]M|^M"  <<<"$status" && dirty+="!"
        grep -qE   "^A|^M "        <<<"$status" && dirty+="+"
        grep -qE   "^D|^.D"        <<<"$status" && dirty+="x"
    fi

    printf "%s⎇ %s%s" "$MAGENTA" "$branch" "$RESET"
    [[ -n "$dirty" ]] && printf " %s[%s]%s" "$YELLOW" "$dirty" "$RESET"
    return 0
}

# ── Build left side: project  path  branch  │  model ────────────────────────
project=$(basename "$cwd")
short_path=$(smart_path "$cwd")

left="${BOLD}${GREEN}${project}${RESET}"

# Omit path when it would just repeat the project name (cwd is top-level)
[[ "$(dirname "$short_path")" != "." ]] && left+=" ${DIM}${short_path}${RESET}"

branch_segment=$(build_branch)
[[ -n "$branch_segment" ]] && left+=" ${branch_segment}"

model_short=$(format_model "$model_id" "$model_name")
thinking=$(thinking_level "$model_id" "$model_name")
model_display="${CYAN}${model_short}${RESET}"
case "$thinking" in
    max)    model_display+=" ${YELLOW}[think:max]${RESET}"    ;;
    xlarge) model_display+=" ${YELLOW}[think:xlarge]${RESET}" ;;
    on)     model_display+=" ${YELLOW}[think]${RESET}"        ;;
esac
left+="${SEP}${model_display}"

# ── Build right side: bar pct  │  tokens  │  cost ───────────────────────────
right=""
if [[ -n "$ctx_pct" ]]; then
    color=$(ctx_color "$ctx_pct")
    bar=$(ctx_bar "$ctx_pct")
    pct_int="${ctx_pct%.*}"
    right="${color}${bar}${RESET} ${DIM}${pct_int}%${RESET}"
    right+="${SEP}${DIM}↑${RESET}$(fmt_tokens "$tokens_in") ${DIM}↓${RESET}$(fmt_tokens "$tokens_out")"
fi

if [[ -n "$cost_usd" ]] && [[ "$cost_usd" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    right+="${SEP}${DIM}$(printf '$%.3f' "$cost_usd")${RESET}"
fi

# ── Output ───────────────────────────────────────────────────────────────────
if [[ -n "$right" ]]; then
    printf "%s%s%s\n" "$left" "$SEP" "$right"
else
    printf "%s\n" "$left"
fi
