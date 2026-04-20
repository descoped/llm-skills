# Kotlin / Android conventions

## Detection

| Signal                                 | Meaning                                   |
| -------------------------------------- | ----------------------------------------- |
| `build.gradle.kts` (Kotlin DSL)        | Kotlin project, modern setup              |
| `build.gradle` + Kotlin plugin         | Kotlin project, older Groovy DSL          |
| `AndroidManifest.xml`                  | Android app / library                     |
| `*.kt` files                           | Kotlin sources                            |
| `settings.gradle.kts` with includes    | Multi-module project                      |
| `compose-compiler` Gradle plugin       | Jetpack Compose                           |
| `ktlint` / `detekt` in build config    | Opinionated linting                       |
| `libs.versions.toml`                   | Version catalog (preferred)               |

## Tooling

| Concern       | Command                                                |
| ------------- | ------------------------------------------------------ |
| Format        | `./gradlew ktlintFormat` (or `./gradlew spotlessApply`) |
| Lint          | `./gradlew ktlintCheck detekt`                         |
| Android lint  | `./gradlew lint`                                       |
| Test (unit)   | `./gradlew test`                                       |
| Test (Android instrumented) | `./gradlew connectedAndroidTest` (requires device/emulator) |
| Build         | `./gradlew build`                                      |
| Clean         | `./gradlew clean`                                      |

Prefer the Gradle wrapper (`./gradlew`) over a globally-installed Gradle.

## Idiomatic rules to port / bootstrap

- Target **Kotlin 2.x** with the K2 compiler for new projects.
- Null safety is the language's killer feature — use it. No `!!` in
  production code except at genuine boundary assertions with a comment.
- Prefer `val` (immutable) over `var`. Mutable state is a design
  signal; justify it.
- Data classes for DTOs; sealed classes / sealed interfaces for closed
  sums. `enum class` for flat enumerations.
- Coroutines over threads and callbacks. `suspend` functions for
  async; structured concurrency via `CoroutineScope` tied to a
  lifecycle (ViewModel, lifecycleScope on Android).
- `Flow` for reactive streams; `StateFlow` for observable state;
  `SharedFlow` for events. Prefer cold flows unless you genuinely need
  multicast.
- No `GlobalScope`. Every coroutine is launched in a scope bound to a
  lifetime.
- Extension functions over utility classes. `String.foo()` beats
  `StringUtils.foo(s)`.
- Explicit visibility: Kotlin defaults to `public`. Mark library-visible
  `internal` / `private` deliberately.
- Dependency injection via Hilt (Android) or Koin / manual DI (non-Android).
  No `Singleton` objects holding mutable state.

## Jetpack Compose

If `compose` is in the build config:

- **Compose is the default UI layer for new Android screens.** XML views
  only for interop, custom drawing at the edge, or legacy screens.
- State hoisting: stateful composables take `state: T` and
  `onEvent: (Event) -> Unit`; stateless composables are previewable.
- `remember { ... }` for composable-local state; `rememberSaveable` when
  configuration change needs to survive.
- `LaunchedEffect` / `DisposableEffect` for side effects. No raw
  `coroutineScope.launch` from inside composables.
- `@Preview` every non-trivial composable; preview with a fake
  `ViewModel` state.
- Theming via `MaterialTheme` with a project-specific `Theme.kt`.

## Testing

- **JUnit 5** (`junit-jupiter`) for new test code; JUnit 4 fine for
  legacy. Pick one per module.
- **MockK** over Mockito for Kotlin — it handles `suspend`, extension
  functions, and Kotlin nullability properly.
- **Turbine** for testing `Flow`.
- **Compose UI tests**: `createAndroidComposeRule` / `createComposeRule`.
- **Robolectric** for Android framework tests that don't need a device.

## Polyglot path-scoping

```yaml
---
paths:
  - "**/*.kt"
  - "**/*.kts"
  - "**/build.gradle*"
  - "**/settings.gradle*"
  - "**/gradle/libs.versions.toml"
  - "**/AndroidManifest.xml"
  - "app/**"
---
```

## Example `.claude/rules/kotlin.md` skeleton

```markdown
# Kotlin / Android

Applies to: Kotlin sources under `app/` and library modules.

## Defaults

- Kotlin 2.x, K2 compiler.
- `val` over `var`. `!!` only at genuine boundary assertions with a
  comment.
- Data classes for DTOs; sealed classes / sealed interfaces for closed
  sums.

## Coroutines

- `suspend` functions + structured concurrency. Scoped to lifecycle
  (ViewModel, lifecycleScope). No `GlobalScope`.
- `StateFlow` for observable UI state; `SharedFlow` for events.

## Jetpack Compose

- Compose for new screens; XML views only for legacy/interop/custom
  drawing.
- State hoisting: split stateful + stateless composables.
- `@Preview` every non-trivial composable.

## Pre-commit pipeline

    ./gradlew ktlintFormat
    ./gradlew ktlintCheck detekt
    ./gradlew test
    ./gradlew lint     # Android lint, if Android
```
