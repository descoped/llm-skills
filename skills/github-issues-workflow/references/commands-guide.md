# Claude Code Commands Guide

Full specification for the four Claude Code slash commands generated per project. All commands follow the same pattern but are customized with project-specific repo name, workspace areas, check commands, and architecture style.

Throughout this document, `{PREFIX}` refers to the project short name, `{REPO}` to the GitHub repo (e.g., `org/repo`), and `{MAIN}` to the main branch name.

## Table of Contents

1. [Command: {PREFIX}-issue](#command-prefix-issue)
2. [Command: {PREFIX}-start](#command-prefix-start)
3. [Command: {PREFIX}-review](#command-prefix-review)
4. [Command: {PREFIX}-address](#command-prefix-address)
5. [Common Elements](#common-elements)

---

## Command: {PREFIX}-issue

**File**: `.claude/commands/{PREFIX}-issue.md`
**Purpose**: Create a GitHub issue with proper labels, templates, and optional design doc.

### Structure

```markdown
# Create Issue

Create a GitHub issue for {PROJECT_NAME}.

## Configuration

\```
Repo: {REPO}
\```

### Workspace Areas

| Area | Path | Description |
|------|------|-------------|
(populated from project config)

## Phase 1: Determine Scope

Ask the user:
1. Which area(s) are affected? (list workspace areas)
2. What type of issue? (Feature, Bug, Enhancement, Docs, Refactor, Test)

## Phase 2: Gather Requirements

Collect (solution-agnostic — no file paths or code specifics):
- Context: Why is this needed?
- Current State: What's the problem? Describe behavior.
- Objective: What should be achieved? Focus on outcomes.
- Acceptance Criteria: Observable behavior only.

If design work needed, note that design doc will be created after issue.

## Phase 3: Search for Duplicates

\```bash
gh issue list --repo {REPO} --state open --search "KEYWORDS"
gh issue list --repo {REPO} --state closed --search "KEYWORDS"
\```

## Phase 4: Select Labels

List available with `gh label list --repo {REPO}` and present area + type + priority + status labels.

## Phase 5: Create Issue

\```bash
gh issue create --repo {REPO} --title "TITLE" --body "BODY" --label "LABELS"
\```

## Phase 6: Organize Issue Documents

After creation (e.g., issue #42):
1. Create folder: `mkdir -p .claude/issues/issue-42`
2. Create `design.md` if needed (self-contained, copy all specs verbatim)
3. Commit: `git add .claude/issues/ && git commit -m "docs: organize issue #42 documents"`

## Issue Templates
(Standard + Cross-Area templates with area checkboxes)

## Rules
- Issues must be solution-agnostic
- Search for duplicates before creating
- Design docs are self-contained — copy specs, never reference external files by path
- Return the issue URL when done
```

---

## Command: {PREFIX}-start

**File**: `.claude/commands/{PREFIX}-start.md`
**Purpose**: Full issue-to-PR workflow: branch, design doc, task file, implementation, PR, review, merge, archive.

### Phase Overview

| Phase | Action |
|-------|--------|
| 1 | Fetch and analyze issue, read ALL referenced documents |
| 2 | Setup: assign, branch, create design.md + task.md (MANDATORY) |
| 3 | Implementation: work through task.md, check off tasks |
| 4 | Verify: check acceptance criteria, run all checks, get user confirmation |
| 5 | Commit and PR: stage specific files, push, create PR |
| 6 | Post-PR: run tests, update issue body, post test results comment |
| 7 | Review: run `/{PREFIX}-review PR_NUMBER` |
| 8 | Merge: squash merge after CI passes |
| 9 | Post-merge: archive `.claude/issues/` to `.claude/history/`, update issue body |

### Critical Elements

**design.md** (MANDATORY) at `.claude/issues/issue-N/design.md`:
- Must be fully self-contained and autonomous
- Copy ALL relevant specs verbatim — never reference external docs by path
- Sections: Specification, Analysis, Design Decisions, Dependencies

**task.md** (MANDATORY) at `.claude/issues/issue-N/task.md`:
- Checkbox tasks checked off during implementation
- Sections: Tasks, Files to Create or Modify, Acceptance Criteria, Progress Log

**Branch naming**:
- Features: `feature/issue-N-short-description`
- Bugs: `fix/issue-N-short-description`
- Docs: `docs/issue-N-short-description`
- Refactoring: `refactor/issue-N-short-description`

**Implementation order** (for multi-area work):
Adapt to architecture style. For hexagonal: Core → Infrastructure → API → Frontend → Mobile.
For layered: Domain → Service → Controller → UI.
For flat: order by dependency.

**Staging**: Never use `git add .` — always stage specific files to avoid committing secrets.

**Working directory**: All `.claude/` and `git` commands run from project root. Use subshell `(cd path && ...)` for commands in subdirectories.

**Post-PR updates**:
- Mark all issue checkboxes `[x]`
- Add design doc as clickable GitHub link
- Post test results comment on PR
- Update task.md with final status

**Post-merge**:
- `git checkout {MAIN} && git pull origin {MAIN}`
- `mv .claude/issues/issue-N .claude/history/`
- Update issue body paths from `.claude/issues/` to `.claude/history/`
- Remove transient doc references

---

## Command: {PREFIX}-review

**File**: `.claude/commands/{PREFIX}-review.md`
**Purpose**: Structured PR review with tech-specific checklist.

### Phase Overview

| Phase | Action |
|-------|--------|
| 1 | Verify on correct PR branch |
| 2 | Fetch PR details (title, body, diff stats, reviews) |
| 3 | Get full diff |
| 4 | Read task/design context and changed files |
| 5 | Run checks locally (all affected areas) |
| 6 | Review checklist |
| 7 | Submit review |

### Review Checklist Categories

**Conventions**:
- Conventional commit format
- Task file exists in `.claude/issues/`
- PR description follows template
- `fixes #X` links issue

**Code Quality** (per tech stack — select relevant from `references/tech-stacks.md`):
- Formatting, linting, type safety
- Error handling patterns
- Architecture compliance
- Security (no secrets, proper auth)

**Testing**:
- All check commands pass per workspace area

**Documentation**:
- Code comments where needed
- PR description complete

### Review Submission

Check for self-review (can't approve own PR):
```bash
PR_AUTHOR=$(gh pr view N --repo {REPO} --json author -q .author.login)
CURRENT_USER=$(gh api user -q .login)
```
- Own PR: use `--comment`
- Others' PR: use `--approve` or `--request-changes`

### Review Format

**Severity levels**: Critical (must fix), Suggestion (non-blocking), Question (clarification needed)

**Initial review**: Overall assessment, critical issues with file:line references and suggested fixes, suggestions, positives, questions, checklist.

**Follow-up review**: Previous feedback status table (Fixed / Not addressed / Explained), new issues, remaining concerns, ready-to-merge assessment.

---

## Command: {PREFIX}-address

**File**: `.claude/commands/{PREFIX}-address.md`
**Purpose**: Systematically address feedback on an issue or PR.

### Phase Overview

| Phase | Action |
|-------|--------|
| 1 | Determine type (PR or issue) and fetch context |
| 2 | Ensure correct branch checkout |
| 3 | Gather all comments/reviews |
| 4 | Create checklist of feedback items |
| 5 | Address each item with commits |
| 6 | Run quality checks |
| 7 | Push changes |
| 8 | Post response with appropriate template |

### Feedback Handling

- **Critical issues**: Must fix, each in separate commit
- **Suggestions**: Consider carefully, implement or explain why not
- **Questions**: Answer in response, make code changes if needed

### Response Templates

**PR review response**: List changes made per feedback item with commit refs, discussion points, items not addressed with reasons.

**Issue update**: Status, progress checkboxes, questions/blockers, next steps.

**Resolution comment**: Summary of implementation, per-area changes, verification checklist.

---

## Common Elements

### Workspace Areas Table

Every command includes a workspace areas table customized per project:

```markdown
| Area | Path | Checks |
|------|------|--------|
```

Populate with the project's actual areas, paths, and check commands from `references/tech-stacks.md`.

For commands that don't need check commands (e.g., `{PREFIX}-issue`), use a Description column instead.

### Issue Folder Structure

```
During work:
.claude/issues/
    issue-N/
        design.md      # Self-contained analysis and specs
        task.md        # Checkbox tasks for progress tracking

After PR merge:
.claude/history/
    issue-N/
        design.md      # Preserved for reference
        task.md        # Preserved, all tasks checked off
```

### Rules (included in every command)

- No AI attribution in commits
- Working directory stays at project root
- Use subshell for subdirectory commands
- Stage specific files, never `git add .`
- Conventional commit format
