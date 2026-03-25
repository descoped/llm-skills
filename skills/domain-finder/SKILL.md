---
name: domain-finder
description: >
  Find creative, available domain names for projects, products, and businesses. Generates candidates
  across 5 naming strategies (invented words, blends, metaphors, compressed phrases, modified words),
  checks real availability via whois, and optionally checks package registries and GitHub. Use when
  the user mentions finding a domain, naming a project, brand naming, checking domain availability,
  or needs name ideas. Also trigger when the user describes a project concept and wants naming
  suggestions, rejects names and wants more options, or asks "what should I call this."
---

# Domain Finder

Find creative, available domain names by combining multiple naming strategies with real-time availability checking.

## Workflow

### Phase 1: Gather Context

Before generating names, understand what you're naming. Ask the user (or extract from conversation):

1. **What does it do?** — one-sentence description of the project/product/business
2. **Who is it for?** — target audience, industry, geography
3. **Tone** — playful, professional, technical, minimal, bold?
4. **Constraints** — must-include words, must-avoid words, preferred length?
5. **TLD preference** — default `.com`, but user may want `.dev`, `.io`, `.no`, `.ai`, `.app`, `.co`, etc.
6. **Also check package registries?** — npm, PyPI, crates.io, GitHub org (optional, useful for dev tools)

If the user has already provided this context in the conversation, don't re-ask. Extract what you can and confirm.

### Permissions Check

This skill runs `whois`, `timeout`, `curl`, and `npm view` commands repeatedly. To avoid constant approval prompts, check if the user's permissions allow these. If not, offer to add them:

```json
{
  "permissions": {
    "allow": [
      "Bash(whois *)",
      "Bash(timeout * whois *)",
      "Bash(curl -s *)",
      "Bash(npm view *)",
      "Bash(dig *)"
    ]
  }
}
```

Add these to `.claude/settings.json` or `.claude/settings.local.json`. If the `claude-settings` skill is installed, suggest running it first. Otherwise, offer to add these permission rules directly before proceeding.

### Phase 2: Generate Candidates

Generate 40-50 candidates per batch using a mix of strategies from `references/naming-strategies.md`. The mix matters — don't lean too heavily on any single approach.

| Strategy | Weight | Why |
|----------|--------|-----|
| Invented words | ~40% | Highest availability, most memorable |
| Word blends | ~20% | Meaningful combinations, natural feel |
| Metaphors | ~15% | Evocative, industry-relevant |
| Compressed phrases | ~10% | Descriptive but compact |
| Modified real words | ~15% | Familiar yet unique |

Consult `references/naming-strategies.md` for detailed phonetic rules, examples, and anti-patterns for each strategy.

### Phase 3: Check Availability

**Verify `whois` is available** before starting:
```bash
command -v whois >/dev/null 2>&1 || echo "whois not found — install with: brew install whois"
```

Check all candidates using the patterns in `references/availability-checks.md`. Key points:

- Use per-domain timeouts (5 seconds each) to avoid hanging on unresponsive whois servers
- Different TLDs return different "not found" strings — use the multi-pattern grep from the reference
- Run in batches of 20-25 to avoid rate limiting
- **Never present unchecked domains** — only show verified available ones

If the user requested package registry checks, also check npm, PyPI, crates.io, and GitHub org availability.

### Phase 4: Present Results

Show only available domains in a clean table:

```
| Domain | Strategy | Notes |
|--------|----------|-------|
| cletho.com | Invented | 6 chars, elegant, no associations |
| pagefold.com | Blend | page + fold, content that unfolds |
| trovano.dev | Invented | Italian feel, modern, 7 chars |
```

Include your top 3 picks with brief reasoning. If package registry results were checked, add a column:

```
| Domain | npm | PyPI | GitHub | Strategy |
|--------|-----|------|--------|----------|
| cletho.com | free | free | free | Invented |
```

### Phase 5: Iterate

If the user doesn't like any:
- Ask what they liked/disliked ("too technical?", "too playful?", "too long?")
- Adjust your strategy mix based on feedback
- Generate another batch of 40-50

If they like the direction of a specific name:
- Generate 10-15 variations of that name
- Check availability on those

Keep going until they find one. Finding a good available domain name usually takes 2-4 rounds.

## Key Principles

- **Front-load invented words** — real English words as `.com` are almost always taken
- **The user's first reaction matters** — if they pause on a name, explore variations of it
- **Don't explain every name** — just the top picks. The table speaks for itself
- **Check multiple TLDs** if the user is open to it — check `.com`, `.dev`, `.app`, `.co` in one batch
- **Avoid domain squatter traps** — very short (3-4 char) domains are almost always parked even if whois says available
- **Cultural awareness** — if the target audience is international, flag names that might have unintended meanings in other languages
- **Trademark caution** — note when a name is similar to an existing well-known brand; the user should do their own trademark search
