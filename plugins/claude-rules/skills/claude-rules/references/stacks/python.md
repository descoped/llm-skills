# Python conventions

## Detection

| Signal                                | Meaning                                  |
| ------------------------------------- | ---------------------------------------- |
| `pyproject.toml`                      | Modern project (poetry / uv / hatch / pdm) |
| `requirements.txt` (+ no pyproject)   | Older project — still common             |
| `setup.py` / `setup.cfg`              | Legacy packaging                         |
| `uv.lock`                             | uv is the package manager                |
| `poetry.lock`                         | Poetry is the package manager            |
| `Pipfile` / `Pipfile.lock`            | pipenv (legacy)                          |
| `.python-version` / `pyproject.toml` `requires-python` | Pinned Python version     |
| `ruff.toml` / `[tool.ruff]`           | Ruff config present                      |

## Tooling

Prefer the modern stack: **`uv` + `ruff` + `pyright`/`mypy` + `pytest`**.

| Concern         | Command                                              |
| --------------- | ---------------------------------------------------- |
| Install deps    | `uv sync` (or `uv pip install -e .`)                 |
| Format          | `uv run ruff format`                                 |
| Lint            | `uv run ruff check --fix`                            |
| Type check      | `uv run pyright` or `uv run mypy src/`               |
| Test            | `uv run pytest -x`                                   |
| Run a tool      | `uv run <tool>`                                      |

If the project uses Poetry, swap `uv run` for `poetry run`. If it's bare
pip/venv, call tools directly.

## Idiomatic rules to port / bootstrap

- Pin the Python version in `pyproject.toml` (`requires-python = ">=3.12"` or similar) and `.python-version`.
- Run `ruff format && ruff check --fix && pyright && pytest -x` before claiming done.
- Type-annotate every public function signature. `from __future__ import annotations` at the top of each module unless targeting very old Python.
- Prefer `pathlib.Path` over `os.path`.
- Don't use bare `except:`. Catch specific exceptions. `except Exception:` only at top-level handlers.
- Prefer dataclasses / Pydantic models / `TypedDict` over dicts with string keys for structured data.
- Use `logging` with module-level loggers (`logger = logging.getLogger(__name__)`), not `print()`.
- Tests live in `tests/`, mirror the source package structure; test functions start with `test_`.
- Keep side effects out of module top-level (no API calls, no `print`) — they run at import time and surprise callers.

## Package manager notes

- `uv` (recommended): fast, handles Python install + venv + deps; pair with `pyproject.toml`.
- `poetry`: mature, but slower; `poetry install` creates venv, `poetry run` executes.
- `pip + venv`: the baseline; for scripts or tiny projects, not polished setups.

Never mix package managers in one project. Pick one and document the choice in CLAUDE.md.

## Async and typing

- Use `async def` + `await` for I/O-bound concurrency. Prefer `asyncio.TaskGroup` over manual gather+cancel.
- Don't block the event loop — no synchronous I/O inside `async def` without a deliberate thread offload.
- Generic functions: use the new `def f[T](x: T) -> T:` syntax if `requires-python >= 3.12`.

## Polyglot path-scoping

```yaml
---
paths:
  - "**/*.py"
  - "**/pyproject.toml"
  - "**/requirements*.txt"
  - "**/uv.lock"
  - "**/poetry.lock"
  - "src/**"
  - "tests/**"
---
```

## Example `.claude/rules/python.md` skeleton

```markdown
# Python

Applies to: Python packages under `src/` and tests under `tests/`.

## Pre-commit pipeline

    uv run ruff format
    uv run ruff check --fix
    uv run pyright
    uv run pytest -x

## Conventions

- Type annotations on all public function signatures.
- `pathlib.Path` over `os.path`.
- Module-level loggers via `logging.getLogger(__name__)`. Never `print`.
- No bare `except:`. Catch specific exceptions.
- Prefer dataclasses / Pydantic models / `TypedDict` for structured data
  over `dict[str, Any]`.

## Async

- `asyncio.TaskGroup` for concurrent awaits. No manual gather+cancel.
- Never block the event loop from inside `async def`.
```
