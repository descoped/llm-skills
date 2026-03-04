# Review PR #$ARGUMENTS

Review a pull request with thorough analysis.

## Configuration

```
Repo: {REPO}
```

### Workspace Areas

{WORKSPACE_AREAS_TABLE_CHECKS}

## Phase 1: Verify Branch

```bash
CURRENT_BRANCH=$(git branch --show-current)
PR_BRANCH=$(gh pr view $ARGUMENTS --repo {REPO} --json headRefName -q .headRefName)
if [ "$CURRENT_BRANCH" != "$PR_BRANCH" ]; then
  echo "WARNING: On $CURRENT_BRANCH but PR is on $PR_BRANCH"
  echo "Switching to PR branch..."
  git fetch origin
  git checkout "$PR_BRANCH"
else
  echo "OK: Already on PR branch $PR_BRANCH"
fi
```

## Phase 2: Fetch PR Details

```bash
gh pr view $ARGUMENTS --repo {REPO} \
  --json title,body,headRefName,baseRefName,additions,deletions,changedFiles,commits,files,reviews,labels
```

**Check for existing reviews**: If previous reviews exist, this is a follow-up review.
- Read ALL previous review comments
- Track each piece of feedback
- Verify each item was addressed

## Phase 3: Get Full Diff

```bash
gh pr diff $ARGUMENTS --repo {REPO}
```

## Phase 4: Read Context and Changed Files

**Read task/design context** (if issue-based PR):
```bash
ls .claude/issues/issue-*/
```
If `task.md` and/or `design.md` exist, read them for implementation intent and acceptance criteria.

**Read changed files**: Use the Read tool on each modified file for full context.

## Phase 5: Run Checks Locally

{LOCAL_CHECK_COMMANDS}

## Phase 6: Review Checklist

### Conventions
- [ ] Commits follow conventional format (`feat:`, `fix:`, `docs:`, etc.)
- [ ] Task file exists in `.claude/issues/` (if issue-based PR)
- [ ] PR description follows template
- [ ] `fixes #X` links issue correctly

{CODE_QUALITY_CHECKLIST}

### Testing
{TESTING_CHECKLIST}

### Documentation
- [ ] Code comments where needed
- [ ] PR description is complete

## Phase 7: Submit Review

**Self-review check**: GitHub does not allow approving your own PR.

```bash
gh pr view $ARGUMENTS --repo {REPO} --json author -q .author.login
gh api user -q .login
```

- Own PR: use `--comment`
- Others' PR: use `--approve` or `--request-changes`

```bash
# Others' PR:
gh pr review $ARGUMENTS --repo {REPO} --approve --body "REVIEW"
gh pr review $ARGUMENTS --repo {REPO} --request-changes --body "REVIEW"

# Own PR (self-review):
gh pr review $ARGUMENTS --repo {REPO} --comment --body "REVIEW"
```

## Review Format

### Initial Review

```markdown
## Review: [Approve | Needs Changes | Comment]

[1-2 sentence overall assessment]

### Critical Issues (if any)

**1. [Issue Title]** (`path/to/file:123`)

[Description of the problem]

\```
// Suggested fix
\```

### Suggestions (non-blocking)

- [Suggestion 1]
- [Suggestion 2]

### What Looks Good

- [Positive point 1]
- [Positive point 2]

### Questions

1. [Clarifying question]

### Checklist

- [x] Conventions followed
- [x] Build passes
- [x] Code quality acceptable
- [ ] [Any failed items]
```

### Follow-up Review

```markdown
## Follow-up Review: [Approve | Needs Changes]

[Assessment of changes since last review]

### Previous Feedback Status

| Feedback | Status |
|----------|--------|
| [Issue 1 summary] | Fixed / Not addressed / Explained |

### New Issues Found (if any)

### Remaining Concerns

### Ready to Merge

[Yes/No and brief explanation]
```

## Severity Levels

- **Critical**: Must fix before merge (bugs, security, broken functionality)
- **Suggestion**: Nice to have, non-blocking (style, minor improvements)
- **Question**: Clarification needed, may or may not need changes

## Rules

- Verify correct PR branch before reviewing
- Read actual files, not just the diff
- Run checks for all affected workspace areas
- Be constructive and specific
- Distinguish critical issues from suggestions
- **Working directory** — `.claude/` and `git` commands run from project root. Use subshell for subdirectory commands.
