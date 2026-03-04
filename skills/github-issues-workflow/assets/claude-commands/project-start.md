# Start Work on Issue #$ARGUMENTS

Pick up a GitHub issue and complete the full workflow: branch, task file, implementation, PR.

## Configuration

```
Repo: {REPO}
```

### Workspace Areas

{WORKSPACE_AREAS_TABLE_CHECKS}

## Phase 1: Fetch and Analyze Issue

```bash
gh issue view $ARGUMENTS --repo {REPO}
```

**Check for existing issue folder**:
```bash
ls -la .claude/issues/issue-$ARGUMENTS/
```

If `design.md` already exists, read it for context and implementation guidance.

### Read ALL Referenced Documents

Scan the issue body for **every document reference** — file paths, planning docs, links to other issues, URLs, or any other referenced material. **Read all of them before proceeding.** Do not skip any reference. These documents contain architectural decisions, constraints, and context that are essential for correct implementation.

Also read any existing source code in the areas the issue will touch — understand what exists before designing what to build.

**Determine scope from issue** — work follows the dependency chain:
{SCOPE_ORDER}

## Phase 2: Setup

1. **Assign the issue**:
```bash
gh issue edit $ARGUMENTS --repo {REPO} --add-assignee @me
```

2. **Ensure on latest main**:
```bash
git checkout {MAIN} && git pull origin {MAIN}
```

3. **Create feature branch** (infer type from issue content):
```bash
# For features
git checkout -b feature/issue-$ARGUMENTS-short-description

# For bugs
git checkout -b fix/issue-$ARGUMENTS-short-description

# For docs
git checkout -b docs/issue-$ARGUMENTS-short-description

# For refactoring
git checkout -b refactor/issue-$ARGUMENTS-short-description
```

4. **Ensure issue folder exists**:
```bash
mkdir -p .claude/issues/issue-$ARGUMENTS
```

5. **Create `design.md`** at `.claude/issues/issue-$ARGUMENTS/design.md` — **MANDATORY for every issue**.

   This document must be **fully autonomous and self-contained**. It is the permanent record of what was built and why. **Never reference external documents by path**. Instead, **copy all relevant specifications, definitions, configurations, constraints, and acceptance criteria verbatim** into the Specification section.

   Required sections:
   ```markdown
   # Issue #N: [Title]

   ## Specification
   [Copy ALL relevant content from planning/architecture documents here verbatim.
   Never reference source documents by path — the content IS the specification.]

   ## Analysis
   - [What the issue requires]
   - [Existing code that will be affected]
   - [Constraints and edge cases]

   ## Design Decisions
   - [Approach chosen and why]
   - [Key types, functions, components to create or modify]

   ## Dependencies
   - [Other issues this depends on]
   - [External packages, APIs, or services involved]
   ```

6. **Create `task.md`** at `.claude/issues/issue-$ARGUMENTS/task.md` — **MANDATORY for every issue**.

   Required format:
   ```markdown
   # Issue #N: [Title]

   ## Tasks

   - [ ] [Task 1 — specific, actionable step]
   - [ ] [Task 2 — specific, actionable step]

   ## Files to Create or Modify

   - `path/to/file` — [what changes]

   ## Acceptance Criteria

   - [ ] [Observable behavior 1]
   - [ ] [Observable behavior 2]

   ## Progress Log

   [Updated during implementation]
   ```

7. **Inform user** setup is complete — present `design.md` summary and task list, then begin implementation.

## Phase 3: Implementation

Work through `task.md` systematically. **Check off each task (`- [x]`) as it is completed.** Update the Progress Log with notes, decisions, and any blockers encountered.

{IMPLEMENTATION_CHECKS}

### Cross-Area Work

{IMPLEMENTATION_ORDER}

**No backward compatibility** — implement directly, no transitional code.

## Phase 4: Verify and Confirm

1. **Verify all acceptance criteria** in task file are met

2. **Run full checks**:
{FULL_CHECK_COMMANDS}

3. **Update task.md** with implementation summary and test results

4. **Ask user for confirmation** before proceeding to commit/PR

## Phase 5: Commit and PR

1. **Stage specific files** (never use `git add .` — risk of staging secrets):
```bash
git add {STAGE_PATHS} .claude/issues/
```

2. **Commit** with conventional format:
```bash
git commit -m "feat: description (fixes #$ARGUMENTS)"
```

3. **Push**:
```bash
git push -u origin BRANCH_NAME
```

4. **Create PR**:
```bash
gh pr create --repo {REPO} \
  --base {MAIN} \
  --title "feat: description (fixes #$ARGUMENTS)" \
  --body "$(cat <<'EOF'
## Summary

[Brief description]

fixes #$ARGUMENTS

## Changes

- [Change 1]
- [Change 2]

## Testing

{PR_TESTING_CHECKLIST}

## Acceptance Criteria

[Copy from task file]
EOF
)" \
  --assignee @me
```

## Phase 6: Post-PR — Run Tests and Update Status

### 1. Run full test suite
{FULL_CHECK_COMMANDS}

### 2. Update GitHub issue body

```bash
gh issue view $ARGUMENTS --repo {REPO} --json body -q '.body'
```

Update: mark all `- [ ]` to `- [x]`, add design doc link.

```bash
gh issue edit $ARGUMENTS --repo {REPO} --body "$(cat <<'EOF'
[UPDATED ISSUE BODY]
EOF
)"
```

### 3. Add test results as PR comment

```bash
gh pr comment PR_NUMBER --repo {REPO} --body "$(cat <<'EOF'
## Test Results

{TEST_RESULTS_TEMPLATE}

All acceptance criteria met. Ready to merge.
EOF
)"
```

### 4. Update task.md with final status

## Phase 7: Review PR

Run `/{PREFIX}-review PR_NUMBER` to perform a structured code review.

- If critical issues found, fix, push, and re-review
- If review passes, proceed to merge

## Phase 8: Merge

```bash
gh pr view PR_NUMBER --repo {REPO} --json title,number,state,url
gh run list --repo {REPO} --limit 5
gh pr merge PR_NUMBER --repo {REPO} --squash
```

## Phase 9: Post-Merge

1. **Switch to main and pull**:
```bash
git checkout {MAIN} && git pull origin {MAIN}
```

2. **Archive issue folder**:
```bash
mkdir -p .claude/history
mv .claude/issues/issue-$ARGUMENTS .claude/history/
git add .claude/history/issue-$ARGUMENTS .claude/issues/ && git commit -m "docs: archive issue-$ARGUMENTS to history"
git push origin {MAIN}
```

3. **Update GitHub issue body** — replace `.claude/issues/` paths with `.claude/history/`

## Worktree Support

For parallel work on multiple issues:
```bash
git worktree add ../{PROJECT}-issue-42 -b feature/issue-42-description
cd ../{PROJECT}-issue-42
# ... work ...
git worktree remove ../{PROJECT}-issue-42
```

## Rules

- **`design.md` is MANDATORY** — created before implementation begins
- **`task.md` is MANDATORY** — with checkbox tasks for progress tracking
- **Read ALL referenced documents** — every reference in the issue body must be read
- **Track progress** — check off tasks as completed
- **User confirmation required** before commit/PR
- Issue folder stays in `.claude/issues/` until PR is **merged**
- Archive to `.claude/history/` only AFTER PR merge
- Use `fixes #$ARGUMENTS` in PR to auto-close issue
- Commits follow conventional format
- **No AI attribution in commits**
- **Working directory** — `.claude/` and `git` commands run from project root. Use subshell `(cd path && ...)` for subdirectory commands.
