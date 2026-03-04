# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**llm-skills** is a collection of LLM skills for AI coding agents. Skills are customizable workflows that teach LLMs to perform specific tasks with repeatable, standardized execution.

- **Repository:** github.com/descoped/llm-skills
- **License:** Apache 2.0

## Repository Structure

```
skills/                    # Skill source directories
  {skill-name}/
    SKILL.md               # Required: frontmatter (name, description) + instructions
    scripts/               # Executable code (Python/Bash)
    references/            # Documentation loaded into context as needed
    assets/                # Templates and files used in output (not loaded into context)
dist/                      # Packaged .skill files for distribution
```

## Skill Anatomy

Each skill requires a `SKILL.md` with YAML frontmatter (`name`, `description`) and markdown body. The description is the primary trigger mechanism — it determines when Claude activates the skill. Keep SKILL.md under 500 lines; split detailed content into `references/` files.

## Build Commands

Skills are validated and packaged using the skill-creator tooling:

```bash
# Validate a skill
python3 <skill-creator-path>/scripts/quick_validate.py skills/{skill-name}

# Package into distributable .skill file
python3 <skill-creator-path>/scripts/package_skill.py skills/{skill-name} dist/
```
