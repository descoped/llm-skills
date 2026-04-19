# Clean Code Review $ARGUMENTS

Perform a deep code quality analysis using clean code engineering principles. Identifies violations of SRP, DRY, dead code, stubs, complexity, coupling, and naming issues. Produces a structured report{ISSUE_COMMAND_NOTE}.

## Scope

`$ARGUMENTS` determines what to review:

{SCOPE_TABLE}

If no argument, ask the user.

## Method

Read files using the Read tool — don't just grep. Understand context, call chains, and module boundaries before flagging anything. **Verify before reporting** — false positives waste time and erode trust.

{DEPENDENCY_ORDER}

For each file or module, evaluate against the categories below. Skip files that are trivially clean (small, focused, well-named).

---

## Categories

{CATEGORIES}

---

## Stack-Specific Checks

{STACK_CHECKS}

---

## Report Format

Present findings grouped by category, sorted by severity within each group.

```markdown
## Clean Code Review: [scope]

**Files reviewed**: N
**Findings**: N total (N critical, N refactor, N minor)

### SRP Violations (N)

| # | File | Symbol | Issue | Suggestion |
|---|------|--------|-------|------------|
| 1 | `path/to/file:45` | `functionOrType` | Does X, Y, and Z | Extract X into [suggestion] |

### DRY Violations (N)

| # | Files | Pattern | Occurrences | Suggestion |
|---|-------|---------|-------------|------------|
| 1 | `path/*.ext` | Repeated pattern | N files | Extract to [shared location] |

### Dead Code (N)

| # | File | Symbol | Evidence |
|---|------|--------|----------|
| 1 | `path/to/file:120` | `symbol_name` | No callers found in codebase |

### Stubs & TODOs (N)

| # | File | Type | Content |
|---|------|------|---------|
| 1 | `path/to/file:88` | TODO | "description" |

### Complexity (N)

| # | File | Symbol | Metric | Suggestion |
|---|------|--------|--------|------------|
| 1 | `path/to/file:200` | `function_name` | 72 lines, 5 nesting levels | Extract sub-operations |

### Coupling Issues (N)

| # | Modules | Issue | Suggestion |
|---|---------|-------|------------|
| 1 | `module_a` -> `module_b` | Direct internal access | Use interface/trait/export |

### Naming Issues (N)

| # | File | Current | Suggested | Reason |
|---|------|---------|-----------|--------|
| 1 | `path/to/file:15` | `data` | `descriptiveName` | Generic name hides intent |
```

After presenting the report, ask the user:
- Which findings to fix now (you'll fix them directly)
- Which to create as issues{ISSUE_COMMAND_REF}
- Which to skip

## Rules

- **Verify before reporting** — read the full call chain. If a function looks unused, search for all references before flagging it.
- **Read actual files** — understand context, not just pattern matches.
- **No false positives** — if you're unsure, investigate deeper or skip it. Every finding must be defensible.
- **Actionable findings only** — each finding must have a concrete suggestion. "This could be better" is not actionable.
- **Respect existing patterns** — if the codebase consistently uses a pattern (even if not your preference), don't flag it unless it causes real problems.
- **Skip trivial files** — config files, generated code, test fixtures, and small utility files (<30 lines) rarely need deep review.
- **Working directory** — use subshell `(cd subdirectory && ...)` for commands in subdirectories.
{PROJECT_RULES}{QUALITY_COMMANDS}
