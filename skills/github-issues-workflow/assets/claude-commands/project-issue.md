# Create Issue

Create a GitHub issue for {PROJECT_NAME}.

## Configuration

```
Repo: {REPO}
```

### Workspace Areas

{WORKSPACE_AREAS_TABLE_DESC}

## Phase 1: Determine Scope

Ask the user:

1. **Which area(s) are affected?** (can be multiple)
{AREA_LIST}

2. **What type of issue?**
   - Feature (new functionality)
   - Bug (something broken)
   - Enhancement (improve existing)
   - Docs (documentation)
   - Refactor (code restructure)
   - Test (test improvements)

## Phase 2: Gather Requirements

Collect from user (solution-agnostic - no file paths or code specifics):

- **Context**: Why is this needed? What's the background?
- **Current State**: What's the problem? Describe behavior, not implementation.
- **Objective**: What should be achieved? Focus on outcomes.
- **Acceptance Criteria**: How do we know it's done? Observable behavior only.

**If the issue requires design work:**
- Create a design doc at `.claude/issues/issue-{N}/design.md` after issue creation (Phase 6)
- The design doc must be fully self-contained — copy all relevant specs into it, never reference external docs by path
- The design doc captures issue-specific analysis, rationale, and code examples

## Phase 3: Search for Duplicates

Before creating, search for existing issues:

```bash
gh issue list --repo {REPO} --state open --search "KEYWORDS"
gh issue list --repo {REPO} --state closed --search "KEYWORDS"
```

If matches found, present to user and ask how to proceed.

## Phase 4: Select Labels

List available labels:
```bash
gh label list --repo {REPO}
```

**Available labels:**

{LABEL_LIST}

## Phase 5: Create Issue

```bash
gh issue create --repo {REPO} \
  --title "TITLE" \
  --body "BODY" \
  --label "LABELS"
```

## Phase 6: Organize Issue Documents

After issue is created (e.g., issue #42):

1. **Create issue folder**:
```bash
mkdir -p .claude/issues/issue-42
```

2. **Create design doc** (if the issue needs design work):
   - Write `.claude/issues/issue-42/design.md` with analysis, rationale, and code examples
   - Read relevant planning docs and copy all pertinent specs into the design doc (design.md must be self-contained)

3. **Commit the organization**:
```bash
git add .claude/issues/
git commit -m "docs: organize issue #42 documents"
```

## Issue Templates

### Standard Template

```markdown
## Context

[Why is this needed?]

**Design Doc**: `.claude/issues/issue-{N}/design.md` (if exists)

## Current State

[What's the problem? Describe behavior.]

## Objective

[What should be achieved?]

## Area

{AREA_CHECKBOXES}

## Tasks

- [ ] [High-level task 1]
- [ ] [High-level task 2]

## Acceptance Criteria

- [ ] [Observable behavior 1]
- [ ] [Observable behavior 2]
```

### Cross-Area Template

```markdown
## Context

[Why this spans multiple areas]

## Objective

[Overall goal]

## Work Breakdown

{CROSS_AREA_BREAKDOWN}

## Coordination

{COORDINATION_ORDER}

## Acceptance Criteria

- [ ] [Overall behavior 1]
- [ ] [Overall behavior 2]
```

## Issue Folder Structure

**During development** (after issue creation):
```
.claude/issues/
    issue-42/
        design.md      # Issue-specific analysis, rationale, code examples
        task.md        # Created by /{PREFIX}-start (implementation details)
```

**After PR merge** (via /{PREFIX}-start):
```
.claude/history/
    issue-42/
        design.md      # Preserved for reference
        task.md        # Preserved for reference
```

## Rules

- Issues must be solution-agnostic (no file paths, no code specifics)
- Search for duplicates before creating
- Create self-contained design docs in `.claude/issues/issue-{N}/` — copy all relevant specs, never reference external files by path
- Return the issue URL to the user when done
