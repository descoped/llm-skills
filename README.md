# llm-skills

A collection of LLM skills for AI coding agents. Skills are customizable workflows that teach LLMs to perform specific tasks with repeatable, standardized execution.

## Skills

### github-issues-workflow

Bootstraps an issue-driven development workflow for monorepo projects. Given a project's tech stack and repo details, it generates all the infrastructure needed for structured issue tracking with Claude Code.

**What it generates:**

| Artifact | Location | Purpose |
|----------|----------|---------|
| Label setup script | `scripts/github/setup-labels.sh` | Creates area, type, priority, and status labels |
| Issue templates | `.github/ISSUE_TEMPLATE/` | General, bug report, and feature request templates |
| PR template | `.github/PULL_REQUEST_TEMPLATE.md` | Standardized pull request format |
| Claude Code commands | `.claude/commands/` | Four slash commands for the full issue lifecycle |

**Supported tech stacks:** Rust, Python, Go, Java | React, Next.js, Svelte v5 | iOS, Android | Tooling crates

#### The Workflow Concept

This skill implements an **issue-driven development workflow** — a structured process where every code change traces back to a GitHub issue and follows a predictable lifecycle from creation to merge.

The core idea: issues stay **solution-agnostic** (describing *what* and *why*, never *how*), while implementation details live in tracked files alongside the code. This separates the problem definition from the solution, keeping issues clean and reusable as documentation.

**Four commands orchestrate the lifecycle:**

```
/{PREFIX}-issue    Create a solution-agnostic GitHub issue
       |
/{PREFIX}-start    Branch, write design.md + task.md, implement, open PR
       |
/{PREFIX}-review   Review PR with tech-specific checklist
       |
/{PREFIX}-address  Address review feedback systematically
```

When work begins on an issue, two mandatory documents are created:

- **`design.md`** — A self-contained specification that copies all relevant context verbatim. It never references external files by path, so it remains valid even if source documents are deleted or moved. This is the permanent record of *what was built and why*.

- **`task.md`** — A checkbox task list that tracks implementation progress. Each task is checked off as completed, providing a clear audit trail.

These files live in `.claude/issues/issue-N/` during active work and are archived to `.claude/history/issue-N/` after the PR merges:

```
During work:                    After merge:
.claude/issues/                 .claude/history/
  issue-42/                       issue-42/
    design.md                       design.md
    task.md                         task.md
```

The full `/{PREFIX}-start` lifecycle covers 9 phases:

1. **Fetch and analyze** — Read the issue and all referenced documents
2. **Setup** — Assign, branch, create design.md and task.md
3. **Implement** — Work through tasks, checking off each one
4. **Verify** — Run all checks, confirm acceptance criteria
5. **Commit and PR** — Stage specific files, push, create PR
6. **Post-PR** — Run tests, update issue body, post results
7. **Review** — Structured review via `/{PREFIX}-review`
8. **Merge** — Squash merge after CI passes
9. **Archive** — Move issue folder to history, update references

This approach works because it gives the AI agent (and human developers) a repeatable, auditable process. Every issue has a design rationale, every PR traces to an issue, and every completed task has a history.

#### Post-Install: Register GitHub Labels

After the skill generates your project files, you **must** run the label setup script to register labels on your GitHub repository before creating issues:

```bash
bash scripts/github/setup-labels.sh
```

This creates the area, type, priority, and status labels that the issue templates and Claude Code commands depend on. Without these labels, the `/{PREFIX}-issue` command cannot apply proper categorization.

## Installation

### Claude Code

1. Add this repository as a plugin marketplace:

   ```
   /plugin https://github.com/descoped/llm-skills
   ```

   Select `github-issues-workflow` from the plugin browser to install it.

2. Restart Claude Code for the skill to become available.

3. Invoke the skill with the slash command:

   ```
   /llm-skills:github-issues-workflow
   ```

### Manual

Copy the skill directory into your project or use the packaged `.skill` file from the `dist/` directory.

## Repository Structure

```
skills/                          Skill source directories
  github-issues-workflow/
    SKILL.md                     Skill metadata and instructions
    scripts/                     Executable templates
    references/                  Tech stack and command specifications
    assets/                      Issue/PR templates, Claude command templates
.claude-plugin/
  marketplace.json               Skills manifest for Claude Code
```

## License

Apache 2.0
