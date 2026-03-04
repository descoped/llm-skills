# Tech Stack Reference

Quick-reference for check commands, package managers, workspace patterns, and label colors per technology.

## Backend Technologies

### Rust
- **Package manager**: Cargo
- **Workspace pattern**: `crates/` or workspace members in `Cargo.toml`
- **Check commands**:
  ```bash
  cargo fmt --all --check
  cargo clippy --all-targets --all-features -- -D warnings
  cargo test --workspace
  ```
- **Per-crate test**: `cargo test -p {crate-name}`
- **Label**: `rust` / color `dea584` (warm orange) / "Rust backend work"
- **Review criteria**: No `unwrap()` in production, proper `Result`/`?` error handling, `thiserror` for library errors, `anyhow` for app errors

### Python
- **Package managers**: uv (preferred), pip, poetry, pipenv
- **Workspace pattern**: `src/` or `packages/` or per-service directories
- **Check commands (uv)**:
  ```bash
  uv run ruff check .
  uv run ruff format --check .
  uv run mypy .
  uv run pytest
  ```
- **Check commands (pip/venv)**:
  ```bash
  ruff check .
  ruff format --check .
  mypy .
  pytest
  ```
- **Label**: `python` / color `3572A5` (python blue) / "Python backend work"
- **Review criteria**: Type hints on public APIs, no bare `except:`, async where appropriate

### Go
- **Package manager**: Go modules
- **Workspace pattern**: `cmd/` for binaries, `internal/` or `pkg/` for libraries
- **Check commands**:
  ```bash
  go fmt ./...
  go vet ./...
  golangci-lint run
  go test ./...
  ```
- **Label**: `go` / color `00ADD8` (go cyan) / "Go backend work"
- **Review criteria**: Error handling (no ignored errors), context propagation, proper goroutine lifecycle

### Java
- **Package managers**: Gradle (preferred), Maven
- **Workspace pattern**: Multi-module Gradle/Maven project
- **Check commands (Gradle)**:
  ```bash
  ./gradlew spotlessCheck
  ./gradlew test
  ./gradlew build
  ```
- **Check commands (Maven)**:
  ```bash
  mvn spotless:check
  mvn test
  mvn package
  ```
- **Label**: `java` / color `b07219` (java orange) / "Java backend work"
- **Review criteria**: No checked exceptions leaking, proper resource management (try-with-resources), null safety

## Frontend Technologies

### React (Vite/CRA)
- **Package managers**: npm, pnpm, bun
- **Workspace pattern**: `frontend/` or `apps/web/`
- **Check commands (npm)**:
  ```bash
  npm run lint
  npm run typecheck
  npm run test
  npm run build
  ```
- **Check commands (bun)**:
  ```bash
  bun run lint
  bun run typecheck
  bun run test
  bun run build
  ```
- **Label**: `frontend` / color `61DAFB` (react blue) / "React frontend work"
- **Review criteria**: No `any` types, proper hook dependencies, no inline styles for reusable components

### Next.js
- **Package managers**: npm, pnpm, bun
- **Workspace pattern**: `apps/web/` or root-level Next.js
- **Check commands**:
  ```bash
  next lint
  npm run typecheck  # or tsc --noEmit
  npm run test
  npm run build      # or next build
  ```
- **Label**: `frontend` / color `000000` (next black) / "Next.js frontend work"
- **Review criteria**: Server vs client components, proper data fetching patterns, no client-side secrets

### Svelte v5
- **Package managers**: bun (preferred), npm, pnpm
- **Workspace pattern**: `frontend/svelte-app/` or `apps/web/`
- **Check commands (bun)**:
  ```bash
  bun run format:check
  bun run lint
  bun run check
  bun run test
  bun run build
  ```
- **Label**: `frontend` / color `ff3e00` (svelte orange) / "Svelte frontend work"
- **Review criteria**: Svelte 5 Runes (`$state`, `$derived`, `$effect`), no client-side UUID generation, TypeScript types (no `any`)

## Mobile Technologies

### iOS (Swift)
- **Build tools**: Xcode, xcodegen, SwiftPM
- **Workspace pattern**: `ios-app/` or `apps/ios/`
- **Check commands**:
  ```bash
  swiftlint lint --config .swiftlint.yml --strict
  xcodebuild -scheme App -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
  xcodebuild -scheme App -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16 Pro' test
  ```
- **Label**: `mobile` / color `006b75` (teal) / "iOS mobile app"
- **Review criteria**: No force unwraps (`try!`, `as!`), proper async/await, UUIDv7 for persisted IDs

### Android (Kotlin)
- **Build tools**: Gradle, Android Studio
- **Workspace pattern**: `android-app/` or `apps/android/`
- **Check commands**:
  ```bash
  ./gradlew ktlintCheck
  ./gradlew testDebugUnitTest
  ./gradlew assembleDebug
  ```
- **Label**: `mobile` / color `3DDC84` (android green) / "Android mobile app"
- **Review criteria**: Null safety, coroutine scope management, proper lifecycle handling

## Tooling

### Rust Crates (Library/CLI)
- **Workspace pattern**: `crates/` with workspace `Cargo.toml`
- **Check commands**: Same as Rust backend
- **Label**: `tooling` / color `dea584` (warm orange) / "Rust tooling crate"
- **Additional**: `cargo doc --no-deps` for documentation checks

### CLI Tools (any language)
- **Label**: `cli` / color `1D76DB` (blue) / "CLI tool"

## Infrastructure

### DevOps / Docker / CI
- **Label**: `infra` / color `0e8a16` (green) / "Infrastructure/DevOps"

### API
- **Label**: `api` / color `5319e7` (purple) / "REST/GraphQL API changes"

### UI/UX
- **Label**: `ui` / color `c5def5` (light blue) / "UI/UX changes"

## Standard Labels (always included)

### Type Labels
| Label | Color | Description |
|-------|-------|-------------|
| `bug` | `d73a4a` (red) | Something isn't working |
| `enhancement` | `a2eeef` (cyan) | New feature or request |
| `docs` | `0075ca` (blue) | Documentation improvements |
| `refactor` | `fbca04` (yellow) | Code restructuring |
| `test` | `bfd4f2` (light purple) | Test improvements |

### Priority Labels
| Label | Color | Description |
|-------|-------|-------------|
| `priority: high` | `b60205` (dark red) | High priority |
| `priority: low` | `c2e0c6` (light green) | Low priority |

### Status Labels
| Label | Color | Description |
|-------|-------|-------------|
| `blocked` | `d93f0b` (orange-red) | Blocked by external dependency |
| `needs-design` | `e99695` (pink) | Needs design work before implementation |
