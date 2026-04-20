# Go conventions

## Detection

| Signal                    | Meaning                                  |
| ------------------------- | ---------------------------------------- |
| `go.mod` at repo root     | Module root                              |
| `*.go` files              | Go sources                               |
| `go.work`                 | Multi-module workspace                   |
| `go.sum`                  | Checked-in dependency hashes             |
| `.golangci.yml` / `.yaml` | Project opinionated about linters        |
| `Makefile` with `go` cmds | Common; honor the tasks defined there    |

## Tooling

| Concern      | Command                                                          |
| ------------ | ---------------------------------------------------------------- |
| Format       | `gofmt -s -w .` or `goimports -w .`                              |
| Vet          | `go vet ./...`                                                   |
| Lint         | `golangci-lint run ./...`                                        |
| Test         | `go test -race -count=1 ./...`                                   |
| Coverage     | `go test -race -coverprofile=coverage.out ./...`                 |
| Build        | `go build ./...`                                                 |
| Mod tidy     | `go mod tidy`                                                    |

Always test with `-race`. `-count=1` disables the test cache when you
want a clean run.

## Idiomatic rules to port / bootstrap

- Run `gofmt -s -w . && goimports -w . && go vet ./... && golangci-lint run ./... && go test -race ./...` before claiming done.
- Error handling: check every error; don't ignore with `_ = err`. Wrap with `fmt.Errorf("doing X: %w", err)` to preserve chain.
- Sentinel errors: declare at package level as `var ErrFoo = errors.New(...)`; compare with `errors.Is`.
- Typed errors: implement `error` via a struct; extract with `errors.As`.
- Context propagation: every exported function that does I/O or is cancellable takes `ctx context.Context` as the first arg. Do not store `context.Context` in structs.
- Goroutine leaks: every goroutine must have a clear exit path (`ctx.Done()`, closed channel, or `sync.WaitGroup`).
- Prefer composition over interface hierarchies. Interfaces in the package that *consumes* them, not the package that defines implementations.
- Keep interfaces small — one or two methods is the default; Go favors narrow interfaces.
- Use `t.Parallel()` in tests that have no shared mutable state; use `t.Cleanup()` over `defer` for test teardown.
- No global mutable state except `sync.Once`-initialized singletons.

## Project layout

- Public API: `pkg/<name>/` (not required, but common); internal: `internal/<name>/` — Go compiler enforces the `internal` boundary.
- `cmd/<tool>/main.go` for binaries.
- Tests beside code: `foo.go` + `foo_test.go`. Integration tests in `*_integration_test.go` gated by a build tag.

## Polyglot path-scoping

```yaml
---
paths:
  - "**/*.go"
  - "**/go.mod"
  - "**/go.sum"
  - "**/go.work"
  - "cmd/**"
  - "internal/**"
  - "pkg/**"
---
```

## Example `.claude/rules/go.md` skeleton

```markdown
# Go

Applies to: Go modules under the repo root (or specify subtree).

## Pre-commit pipeline

    gofmt -s -w .
    goimports -w .
    go vet ./...
    golangci-lint run ./...
    go test -race -count=1 ./...

## Error handling

- Wrap errors with `fmt.Errorf("context: %w", err)`. Never drop errors.
- Sentinels at package level: `var ErrNotFound = errors.New("not found")`.
  Compare with `errors.Is`.
- Typed errors: `errors.As(err, &target)`.

## Context

- First parameter of every I/O or cancellable function is `ctx context.Context`.
- Don't store `context.Context` in structs. Pass it explicitly.

## Concurrency

- Every goroutine has a documented exit path (ctx, closed channel, waitgroup).
- Detect races: `go test -race ./...` (required in CI).
```
