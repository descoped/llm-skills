# Rust conventions

## Detection

| Signal                      | Meaning                          |
| --------------------------- | -------------------------------- |
| `Cargo.toml` at repo root   | Single-crate or workspace root   |
| `Cargo.toml` at subdir root | Member of a workspace            |
| `*.rs` files                | Rust sources                     |
| `rust-toolchain.toml`       | Pinned toolchain (honor it)      |
| `clippy.toml`               | Project has opinionated lints    |
| `rustfmt.toml`              | Project has custom format rules  |

## Tooling

| Concern        | Command                                                |
| -------------- | ------------------------------------------------------ |
| Format         | `cargo fmt --all`                                      |
| Lint           | `cargo clippy --all-targets --all-features -- -D warnings` |
| Quick compile  | `cargo check --all-targets`                            |
| Test           | `cargo test --all-features`                            |
| Build          | `cargo build --release` (only when shipping)           |
| Doc lint       | `cargo doc --no-deps` (warn on missing docs if opted in) |

Prefer `cargo clippy` over `cargo check` as the quality gate — clippy is a
superset and catches real bugs.

## Idiomatic rules to port / bootstrap

Include in `.claude/rules/rust.md` (or equivalent) unless the source
already covers them:

- Run `cargo fmt --all && cargo clippy --all-targets --all-features -- -D warnings && cargo test` before declaring work done.
- Prefer `Result<T, E>` over panics in library code. Panics are acceptable in `main`/CLI for unrecoverable state.
- No `.unwrap()` or `.expect()` in production paths — use `?`, `let-else`, or explicit pattern matching. `unwrap` is fine in tests.
- Use `thiserror` for library error enums, `anyhow` for application error chains. Don't mix.
- Avoid `unsafe` outside FFI. When necessary, add a doc comment stating the invariants the caller must uphold.
- Prefer iterators and combinators over index-based loops when it reads cleanly.
- Use `#[must_use]` on types representing critical results (e.g., `Result`, builders).
- Derive `Debug` on every public type unless it contains secrets.
- Clippy `-D warnings` is the gate — don't silence lints with `#[allow]` without a one-line justification comment.

## Workspace-specific

- Every workspace member should re-export its public types from `lib.rs` so consumers have one entry point.
- Shared deps via `workspace.dependencies` in root `Cargo.toml`; members reference with `dep = { workspace = true }`.
- Never hand-write versions for workspace crates — use `{ path = "...", version = "x.y" }` only when publishing externally.

## Polyglot path-scoping

In a polyglot monorepo, scope Rust rules to the Rust subtree:

```yaml
---
paths:
  - "**/*.rs"
  - "**/Cargo.toml"
  - "**/Cargo.lock"
  - "crates/**"
  - "rust-toolchain.toml"
---
```

Adjust the directory globs to match the actual workspace layout (e.g.,
`packages/rust-core/**`).

## Example `.claude/rules/rust.md` skeleton

```markdown
# Rust

Applies to: Rust crates under `crates/`.

## Pre-commit pipeline

Run before every commit / "I'm done" claim:

    cargo fmt --all
    cargo clippy --all-targets --all-features -- -D warnings
    cargo test --all-features

Clippy `-D warnings` is the quality gate. Don't `#[allow]` a lint without
a one-line justification.

## Error handling

- Library crates: `thiserror` for enums with semantic variants.
- Binary / application crates: `anyhow` for error chains at boundaries.
- No `.unwrap()` / `.expect()` outside tests. Use `?`, `let-else`, or
  pattern matching.

## Unsafe

Unsafe is allowed only for FFI or performance-critical paths where the
alternative was measured and slower. Every `unsafe` block must have a
doc comment stating the caller-side invariants.
```
