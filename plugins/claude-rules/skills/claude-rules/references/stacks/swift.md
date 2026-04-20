# Swift / iOS conventions

## Detection

| Signal                            | Meaning                                        |
| --------------------------------- | ---------------------------------------------- |
| `Package.swift`                   | Swift Package Manager project / library        |
| `*.xcodeproj` / `*.xcworkspace`   | Xcode-managed app / framework                  |
| `*.swift` files                   | Swift sources                                  |
| `Podfile`                         | CocoaPods (legacy — prefer SPM for new work)   |
| `Cartfile`                        | Carthage (legacy)                              |
| `*.mlmodel` / `Info.plist`        | iOS/macOS app artefacts                        |
| `.swiftformat` / `.swift-format.json` | Project has opinionated format rules       |
| `.swiftlint.yml`                  | SwiftLint config                               |

## Tooling

| Concern       | Command                                                                       |
| ------------- | ----------------------------------------------------------------------------- |
| Format        | `swift-format format -i -r .` (or `swiftformat .`)                            |
| Lint          | `swiftlint`                                                                   |
| SPM build     | `swift build`                                                                 |
| SPM test      | `swift test`                                                                  |
| Xcode build   | `xcodebuild -scheme {SCHEME} -destination '{DESTINATION}' build`              |
| Xcode test    | `xcodebuild -scheme {SCHEME} -destination '{DESTINATION}' test`               |

**Do not hard-code schemes or destinations.** The user's scheme and
destination are project-specific — ask or template with `{SCHEME}` /
`{DESTINATION}` placeholders. Example destinations:
`platform=iOS Simulator,name=iPhone 16 Pro`, `platform=macOS`.

## Idiomatic rules to port / bootstrap

- Target **Swift 6** / strict concurrency if the project can adopt it.
  Annotate concurrency-unsafe code with `@unchecked Sendable` only with a
  comment justifying the invariant.
- Use `async`/`await` + structured concurrency (`TaskGroup`) over
  callbacks and manual `DispatchQueue` ceremony.
- `actor` for isolated mutable state that's accessed across tasks.
- Prefer `struct` over `class` unless reference semantics are required.
- Avoid force-unwrapping (`!`). Use `guard let`, `if let`, or `??`. Force
  unwrap is acceptable only for genuine programmer errors (e.g.,
  `UIImage(named:)` for an asset you shipped with the bundle).
- Protocol-oriented design: prefer small protocols + composition over
  deep inheritance hierarchies.
- Use `Result<T, Error>` for synchronous fallible operations; throw for
  `async throws`.
- Access control: `internal` is the default; only make things `public`
  or `open` deliberately.
- Tests: **Swift Testing** (`import Testing`, `@Test`) for new projects
  targeting Swift 6; XCTest is fine for legacy and for UI tests. Don't
  mix styles in a single target.

## SwiftUI vs UIKit

- **SwiftUI**: default for new apps. Observable state via `@Observable`
  (Swift 5.9+) or the older `@StateObject` / `@ObservedObject`. Prefer
  `@Observable` macro.
- **UIKit**: still fine for complex interactive UI (camera, custom drawing,
  legacy codebases). Don't mix UIKit and SwiftUI casually — pick per
  screen, wrap with `UIViewRepresentable` if needed.

## Dependency injection

- Constructor injection over singletons. Pass dependencies through
  `init`, not global `shared`.
- `@Environment` for SwiftUI-scoped injection is fine.

## Polyglot path-scoping

```yaml
---
paths:
  - "**/*.swift"
  - "**/Package.swift"
  - "**/Package.resolved"
  - "**/*.xcodeproj/**"
  - "**/*.xcworkspace/**"
  - "**/Info.plist"
---
```

## Example `.claude/rules/swift.md` skeleton

```markdown
# Swift / iOS

Applies to: Swift sources and Xcode project under the repo root.

## Concurrency

- Swift 6 strict concurrency. Annotate exceptions deliberately.
- `async`/`await` + structured concurrency. No manual DispatchQueue.
- `actor` for isolated shared mutable state.

## Values first

- Prefer `struct` over `class` unless reference semantics are required.
- No force-unwraps outside programmer-error invariants (e.g., bundled
  assets).
- Access control: `internal` default; `public` and `open` only when
  deliberately crossing module boundaries.

## UI

- SwiftUI for new screens; `@Observable` for observable models.
- UIKit for complex interaction (camera, custom drawing). Bridge via
  `UIViewRepresentable` when needed.

## Testing

- Swift Testing (`@Test`) for new code.
- XCTest for UI tests and legacy code.

## Build

    xcodebuild -scheme <scheme> -destination '<destination>' test

Ask the user for the scheme and destination — don't hard-code.
```
