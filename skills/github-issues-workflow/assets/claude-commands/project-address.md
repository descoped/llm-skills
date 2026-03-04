# Address Feedback on Issue/PR #$ARGUMENTS

Respond to comments on an issue or PR.

## Configuration

```
Repo: {REPO}
```

### Workspace Areas

{WORKSPACE_AREAS_TABLE_CHECKS}

## Phase 1: Determine Type and Fetch Context

```bash
# Try PR first, then issue
gh pr view $ARGUMENTS --repo {REPO} --json title,body,state,headRefName 2>/dev/null || \
gh issue view $ARGUMENTS --repo {REPO}
```

## Phase 2: Ensure Correct Branch

**For PRs** — checkout the PR branch before making changes:
```bash
gh pr checkout $ARGUMENTS --repo {REPO}
```

**For Issues** — check if a branch exists for this issue:
```bash
git branch --list "*issue-$ARGUMENTS*"
```
If a branch exists, check it out. If not, the feedback may be pre-implementation.

**Read task context** (if exists):
```bash
ls .claude/issues/issue-$ARGUMENTS/
```
If `task.md` and/or `design.md` exist, read them for context.

## Phase 3: Gather Comments

**For PRs**:
```bash
gh pr view $ARGUMENTS --repo {REPO} --json reviews
gh api repos/{REPO}/pulls/$ARGUMENTS/comments
```

**For Issues**:
```bash
gh api repos/{REPO}/issues/$ARGUMENTS/comments
```

## Phase 4: Create Checklist

List all feedback items that need addressing:
- [ ] Item 1 from reviewer/commenter
- [ ] Item 2 from reviewer/commenter

## Phase 5: Address Each Item

For each feedback item:
1. Read and understand the feedback
2. Read the relevant code context
3. Make necessary changes
4. Commit with descriptive message referencing the feedback

```bash
git commit -m "fix: address review - specific change description"
```

## Phase 6: Run Quality Checks

{LOCAL_CHECK_COMMANDS}

## Phase 7: Push Changes

```bash
git push
```

## Phase 8: Respond

**For PRs**:
```bash
gh pr comment $ARGUMENTS --repo {REPO} --body "RESPONSE"
```

**For Issues**:
```bash
gh issue comment $ARGUMENTS --repo {REPO} --body "RESPONSE"
```

## Response Templates

### PR Review Response

```markdown
## Addressed Review Feedback

Thanks for the review! Here's what I've addressed:

### Changes Made

**1. [Feedback summary]**
- [What was changed]
- Commit: `abc1234`

### Discussion Points

> [Quote if something needs discussion]

[Your response or explanation]

### Not Addressed (if any)

- **[Item]**: [Reason]
```

### Issue Update

```markdown
## Update on Issue #$ARGUMENTS

### Status: [In Progress | Blocked | Resolved]

### Progress

- [x] [What's been done]
- [ ] [What's remaining]

### Questions/Blockers (if any)

### Next Steps
```

### Resolution Comment

```markdown
## Resolved

This issue has been resolved in PR #XX.

### Summary

[What was implemented]

### Changes

{AREA_CHANGES_TEMPLATE}

### Verified

{VERIFICATION_CHECKLIST}
```

## Handling Different Feedback Types

### Critical Issues
- Must be fixed
- Each fix in separate commit
- Explain what was done

### Suggestions
- Consider carefully
- Implement if agreeable
- If not implementing, explain why respectfully

### Questions
- Answer in response comment
- Make code changes if answer reveals issue

## Rules

- Address ALL comments (fix or explain why not)
- Run checks for all affected workspace areas before pushing
- Push changes BEFORE posting response
- Be professional and constructive
- **Working directory** — `.claude/` and `git` commands run from project root. Use subshell for subdirectory commands.
