---
name: "slack-message"
description: "Write Slack messages — plain text with Slack markup, direct and concise, copy-paste ready"
---
# Slack Message Skill

Write messages for Slack using plain-text markup. Output is raw markup in a code block — ready to copy-paste.

## Slack Markup Reference

Slack uses its own markup (not standard Markdown). Use only these:

| Format | Syntax | Renders as |
|--------|--------|------------|
| Bold | `*text*` | **text** |
| Italic | `_text_` | _text_ |
| Strikethrough | `~text~` | ~~text~~ |
| Inline code | `` `text` `` | `text` |
| Code block | ` ```text``` ` | pre-formatted block |
| Blockquote | `> text` | indented quote |
| Unordered list | `- item` or `• item` | bullet list |
| Ordered list | `1. item` | numbered list |
| Link | `<url\|display text>` | clickable link |

### Not supported in Slack

- No `#` headings in messages (only in Canvas/posts)
- No `[text](url)` links — use `<url\|text>` angle-bracket syntax
- No native tables — use ASCII tables inside code blocks (see below)
- No nested formatting (no bold-italic combos)
- No images inline — attach separately

### Emphasis conventions

- `*bold*` for section labels, key terms, status words
- `_italic_` for emphasis within a sentence, names of things
- `` `backticks` `` for code tokens, file paths, commands, branch names, config values
- ` ```code blocks``` ` for multi-line output, logs, commands to copy
- `- ` dash-space for bullet lists (not `*` which Slack reads as bold)

### ASCII Tables

Slack has no native table support. Use code blocks with ASCII-formatted tables. Columns must be properly aligned with consistent spacing so they render correctly in Slack's monospace font.

**Formatting rules:**
- Wrap the table in triple backticks (` ``` `)
- Use pipes `|` as column separators
- Use dashes `-` for header separator rows
- Pad every cell to match the widest value in its column
- Left-align text columns, right-align number columns
- Keep tables narrow — Slack code blocks don't scroll horizontally on mobile

**Example — simple status table:**
```
```
Package          Tests   Status
────────────────────────────────
auth-service       315   passed
worker-engine      191   passed
infra-core         187   passed
data-processor     192   passed
Total            1,742   passed
```
```

**Example — comparison table with mixed alignment:**
```
```
Feature            Before              After
──────────────────────────────────────────────────
Config format      XML                 YAML
Deploy time        12 min              45 sec
Rollback           manual              automated
Health checks      none                3 endpoints
```
```

**Example — compact key-value table:**
```
```
Metric              Value
───────────────────────────
Requests handled    5,058
Avg latency          42ms
Error rate          0.00%
Uptime               100%
```
```

**Column width calculation:**
1. Find the longest string in each column (including the header)
2. Pad all cells in that column to match, plus 2 spaces between columns
3. Right-align columns ONLY when ALL values are plain numbers (no mixed text+number)
4. If a column mixes numbers with descriptive text (e.g., `52` and `5,058 (3 × 1,686)`), left-align the entire column — mixed alignment looks broken in monospace
5. The separator row spans the full table width using `─` (U+2500) or `-`

**Alignment pitfall:** Never right-align a column that contains both short numbers (`52`) and long descriptive values (`~9,000 (935 × 2 × 3)`). The short values float far right while long values start left — creating a jagged, misaligned appearance. Left-align instead.

## Tone and Voice

- *Direct* — get to the point, no preamble
- *Personal* — use "I", "we", say who did what
- *Pleasant* — warm but not performative, no corporate buzzwords
- *Factual* — state what happened, what changed, what's next
- *Concise* — trim filler words, shorten where possible without losing content
- *Understated* — celebrate achievements matter-of-factly, don't oversell

### Do NOT

- Start with "Hey team", "Hi everyone", "Hello all"
- Use filler like "I'm excited to announce", "I wanted to share", "Just a quick update"
- Use corporate speak: "synergy", "leverage", "align", "circle back"
- Use superlatives: "amazing", "incredible", "game-changing"
- Add emojis unless the user explicitly asks for them
- Write walls of text — break into short paragraphs or bullets

### Do

- Jump straight into the content
- Use the person's name when addressing someone specific
- State facts: what was done, what the result is, what's next
- Use bullets for lists of changes, items, or status
- Keep it scannable — someone should get the point in 5 seconds

## Message Patterns

### Status Update

```
*Auth token refresh fix* shipped to dev

Root cause: refresh token was stored with session TTL instead of its own expiry. Tokens expired before the refresh window opened.

Fix: store refresh expiry separately, trigger refresh 60s before access token expires.

- All auth tests pass
- Tested against staging OAuth provider
- Merged to main
```

### Completion / Milestone

```
API migration done — *84/84 endpoints* ported to v2, zero regressions.

Phase 1 (auth, users, orgs): 45/45
Phase 2 (billing, webhooks, admin): 39/39

Test suite at `scripts/api-migration-tests.sh`.
```

### Bug Report / Issue Filed

```
Filed #42 — `session.refresh()` returns 401 when called within 5s of token issue

*Repro*: create session, immediately call refresh. Returns 401 instead of new token.

*Likely cause*: server-side `not_before` claim with clock skew tolerance.
```

### Asking for Input

```
Two options for the cache key format:

*A)* `{user_id}:{resource}:{hash}` — flat, simple lookup
*B)* `cache/{user_id}/{resource}/{hash}` — hierarchical, supports prefix invalidation

I lean toward B (easier cache busting per user). Thoughts?
```

### PR / Merge Notification

```
PR #87 merged — webhook retry with exponential backoff

- Failed deliveries retry 3x with 1s/5s/30s delays
- Dead letter queue after max retries
- Dashboard shows delivery status per endpoint

CLI: `myapp webhooks retry <delivery-id>`
```

### Data Summary with Table

```
*Test suite verification* — 52/52 tests passed, zero regressions

```
Session   Tests   Passed   Failed
────────────────────────────────────
S1           28       28        0
S2           24       24        0
Total        52       52        0
```

5,058 requests processed across 3 runs, 100% success rate.
```

## Rules

1. Output ONLY the Slack message — no explanation, no "here's the message", no wrapper
2. Use Slack markup syntax (not GitHub Markdown)
3. **Output as a raw code block** — wrap the entire message in triple backticks so the user sees the literal Slack markup characters (`*`, `_`, `` ` ``, etc.) and can copy-paste directly into Slack. The code block fence itself is NOT part of the message.
4. Keep under 2000 characters unless the content genuinely requires more
5. If the user provides bullet points or notes, restructure into a clean message — don't just echo
6. If the message is about code changes, include relevant paths, commands, or PR numbers
7. Match the urgency and formality to the context — a bug report is more structured than a quick FYI
