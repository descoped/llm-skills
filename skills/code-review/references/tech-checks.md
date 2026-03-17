# Stack-Specific Quality Checks

Additional checks layered on top of the 7 universal categories. Include only sections matching the target project's tech stacks.

## Rust

- `unwrap()` without context — use `expect("reason")` or `?` operator
- `clone()` where a reference would suffice
- Manual `impl Display` where `#[derive]` or `thiserror` suffices
- `Box<dyn Error>` in library code — use typed errors (`thiserror` for libraries, `anyhow` for apps)
- Unnecessary `pub` visibility — should be `pub(crate)` or private
- Missing `#[must_use]` on functions returning important values
- Raw string indexing instead of `.chars()` or `.bytes()`

**Check commands:**
```bash
cargo fmt --all --check
cargo clippy --all-targets --all-features -- -D warnings
cargo test --workspace
```

## Python

- Missing type hints on public function signatures
- Bare `except:` or `except Exception:` without re-raise or logging
- Mutable default arguments (`def f(items=[])`)
- `import *` — always use explicit imports
- Blocking calls in async functions (synchronous I/O in `async def`)
- f-strings or `.format()` in logging calls (use `%s` style for lazy evaluation)
- Modern Python: prefer `x | y` unions over `Union[X, Y]`, `list[T]` over `List[T]`

**Check commands (uv):**
```bash
uv run ruff check .
uv run ruff format --check .
uv run mypy .
uv run pytest
```

**Check commands (pip/venv):**
```bash
ruff check . && ruff format --check . && mypy . && pytest
```

## Go

- Ignored errors (`val, _ := riskyCall()` without justification)
- Missing error context (`return err` instead of `fmt.Errorf("context: %w", err)`)
- `panic()` in library code — return errors instead
- Missing `context.Context` propagation in functions that do I/O
- Goroutine leaks (fire-and-forget goroutines without lifecycle management)
- `interface{}` / `any` where a concrete type or generic would be safer
- `init()` functions with side effects

**Check commands:**
```bash
go fmt ./...
go vet ./...
golangci-lint run
go test ./...
```

## Java

- Checked exceptions leaking across module boundaries
- Missing `try-with-resources` for `AutoCloseable` resources
- Null returns where `Optional` is appropriate
- Raw types instead of generics (`List` instead of `List<String>`)
- Mutable static fields
- `System.out.println` instead of proper logging

**Check commands (Gradle):**
```bash
./gradlew spotlessCheck
./gradlew test
./gradlew build
```

**Check commands (Maven):**
```bash
mvn spotless:check && mvn test && mvn package
```

## Kotlin

- Platform types from Java interop without null checks
- `!!` (non-null assertion) — use safe calls or `requireNotNull` with message
- Missing `sealed` on exhaustive hierarchies
- Coroutine scope leaks (launching in `GlobalScope`)
- Mutable `var` where `val` suffices

**Check commands:**
```bash
./gradlew ktlintCheck
./gradlew testDebugUnitTest
./gradlew assembleDebug
```

## TypeScript (General)

- `any` type annotations — use `unknown`, typed generics, or proper interfaces
- Missing return types on exported functions
- Non-null assertion (`!`) without justification
- `as` type casts hiding type errors — prefer type guards
- Unused type exports
- `enum` where a union type (`type X = 'a' | 'b'`) is simpler

**Check commands (npm):**
```bash
npm run lint && npm run typecheck
```

**Check commands (bun):**
```bash
bun run lint && bun run typecheck
```

**Check commands (pnpm):**
```bash
pnpm run lint && pnpm run typecheck
```

## React

- `useEffect` with missing or incorrect dependency arrays
- Direct DOM manipulation instead of React state/refs
- Inline styles for reusable components (should use CSS/styled/theme)
- Missing `key` props in list rendering
- Business logic inside component bodies (should extract to hooks or utilities)
- `forwardRef` missing where a component wraps a native element
- Prop drilling through >3 levels (consider context or composition)

## Next.js

- Client components (`'use client'`) that could be server components
- Server components using client-side APIs (`useState`, `useEffect`, event handlers)
- Client-side secrets exposure (API keys in client components)
- `fetch()` in components instead of server-side data fetching patterns
- Missing `loading.tsx` / `error.tsx` boundary files
- Hardcoded strings that should come from CMS or i18n

## Svelte 5

- Legacy Svelte 4 syntax (`$:` reactive, `export let` props, `$store` subscriptions)
- Should use Svelte 5 runes: `$state`, `$derived`, `$effect`, `$props`
- Client-side UUID generation (should happen server-side)
- Direct `fetch()` in components (should use load functions or API client layer)
- Inline type definitions (should be in shared types module)
- `any` type annotations

**Check commands (bun):**
```bash
bun run format:check && bun run lint && bun run check && bun run test && bun run build
```

## Swift / iOS

- Force unwraps (`!`, `try!`, `as!`) without SwiftLint disable comment
- `UUID()` for persisted entity IDs (use UUIDv7 or server-generated)
- Business logic in SwiftUI view bodies
- `@ObservedObject` / `@Published` instead of `@Observable` (Swift 5.9+)
- Massive view bodies (>100 lines) — extract subviews
- Missing `@MainActor` on UI-mutating code
- Retain cycles in closures (missing `[weak self]`)

**Check commands:**
```bash
swiftlint lint --strict
xcodebuild -scheme App -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
xcodebuild -scheme App -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16 Pro' test
```

## Android / Kotlin

- Force unwraps (`!!`) without documented reason
- `GlobalScope` launches (use structured concurrency with `viewModelScope` / `lifecycleScope`)
- Business logic in Activities/Fragments (should be in ViewModels or UseCases)
- Hardcoded dimensions/colors (should reference resources)
- Missing null checks on platform types from Java APIs
- Lifecycle-unaware observers

**Check commands:**
```bash
./gradlew ktlintCheck
./gradlew testDebugUnitTest
./gradlew assembleDebug
```
