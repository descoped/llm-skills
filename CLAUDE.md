# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**llm-skills** is a collection of LLM skills for AI coding agents. Skills are customizable workflows that teach LLMs to perform specific tasks with repeatable, standardized execution.

- **Repository:** github.com/descoped/llm-skills
- **License:** Apache 2.0

## Repository Structure

Each skill is packaged as its own isolated plugin. The plugin root contains a `skills/<skill-name>/` directory so Claude Code's per-plugin skill discovery only finds that one skill — installing one plugin never exposes skills from another.

```
plugins/                           # One plugin directory per skill
  {skill-name}/                    # Plugin root (source path in marketplace.json)
    skills/{skill-name}/
      SKILL.md                     # Required: frontmatter (name, description) + instructions
      scripts/                     # Executable code (Python/Bash)
      references/                  # Documentation loaded into context as needed
      assets/                      # Templates and files used in output (not loaded into context)
.claude-plugin/
  marketplace.json                 # Plugin manifest
dist/                              # Packaged .skill files for distribution
```

## Skill Anatomy

Each skill requires a `SKILL.md` with YAML frontmatter (`name`, `description`) and markdown body. The description is the primary trigger mechanism — it determines when Claude activates the skill. Keep SKILL.md under 500 lines; split detailed content into `references/` files.

## Marketplace

Plugins are registered in `.claude-plugin/marketplace.json`. Each plugin entry requires `name`, `source`, and `description`, with `source` pointing at `./plugins/<name>`. The `strict` field controls component authority:

- **`strict: true`** (default) — `plugin.json` is authoritative; marketplace supplements it.
- **`strict: false`** — marketplace entry is the entire definition; no `plugin.json` should declare components.

Use `strict: false` for skills without a `plugin.json` (e.g., standalone SKILL.md-only skills).

### Isolated plugin layout

Every plugin's `source` points at its own subdirectory under `./plugins/<name>`, not at the repo root. This keeps skill discovery scoped — Claude Code walks `<plugin-source>/skills/*/SKILL.md` and finds only that plugin's skill. Using a shared `source: "./"` would instead register every skill in the repo under every installed plugin's namespace.

## Build Commands

Skills are validated and packaged using the skill-creator tooling:

```bash
# Validate a skill
python3 <skill-creator-path>/scripts/quick_validate.py plugins/{skill-name}/skills/{skill-name}

# Package into distributable .skill file
python3 <skill-creator-path>/scripts/package_skill.py plugins/{skill-name}/skills/{skill-name} dist/
```

## References

- [Claude Code Plugins](https://code.claude.com/docs/en/plugins)
- [Plugin Marketplaces](https://code.claude.com/docs/en/plugin-marketplaces)
- [Plugins Reference](https://code.claude.com/docs/en/plugins-reference)
- [Claude Code Settings](https://code.claude.com/docs/en/settings)
