# Java conventions

## Detection

| Signal                                 | Meaning                                   |
| -------------------------------------- | ----------------------------------------- |
| `pom.xml`                              | Maven build                               |
| `build.gradle` / `build.gradle.kts`    | Gradle build                              |
| `*.java` files (no `*.kt`)             | Pure Java (mixed with `.kt` → see kotlin.md) |
| `src/main/java/` / `src/test/java/`    | Maven standard layout                     |
| `pom.xml` `maven.compiler.release`     | Target Java version                       |
| `.sdkmanrc`                            | SDKMAN-pinned JDK                         |

## Tooling

| Concern       | Maven                                  | Gradle                                      |
| ------------- | -------------------------------------- | ------------------------------------------- |
| Build         | `mvn compile`                          | `./gradlew build`                           |
| Test          | `mvn test`                             | `./gradlew test`                            |
| Package       | `mvn package`                          | `./gradlew assemble`                        |
| Verify + int. tests | `mvn verify`                     | `./gradlew check`                           |
| Clean         | `mvn clean`                            | `./gradlew clean`                           |
| Format        | `mvn spotless:apply`                   | `./gradlew spotlessApply`                   |
| Lint / style  | `mvn checkstyle:check` / `mvn spotbugs:check` | `./gradlew checkstyleMain spotbugsMain` |

Prefer the Gradle wrapper (`./gradlew`) or Maven wrapper (`./mvnw`) over
globally-installed versions.

## Idiomatic rules to port / bootstrap

- Target **Java 21 LTS** for new services. Java 17 is acceptable for
  long-running projects pinned to an older LTS.
- Prefer **records** for immutable data holders. Stop writing POJOs with
  getters by hand.
- **Sealed classes / interfaces** + pattern matching for closed sums.
  Exhaustive `switch` expressions over `instanceof` chains.
- `var` for local variables where the inferred type is obvious. Don't use
  `var` when the type isn't clear from the right-hand side.
- `Optional<T>` only for return types signaling "may be absent". Don't
  stuff it into fields, parameters, or collections.
- **No checked exceptions in new code unless mandated by an interface**
  — they poison call-site ergonomics. Wrap with a runtime exception at
  the boundary.
- **Immutability by default.** `final` fields, unmodifiable collections
  (`List.copyOf`, `Map.copyOf`, `Set.copyOf`).
- Dependency injection via constructor, not field or setter injection.
- Logging via SLF4J with a specific backend (Logback / Log4j 2). No
  `System.out.println` in application code.
- Tests: **JUnit 5** (`org.junit.jupiter`). **AssertJ** for assertions.
  **Mockito** when mocks are genuinely needed.

## Spring / Jakarta EE notes

If `spring-boot-starter-*` is in the build:

- Constructor injection for beans. Avoid `@Autowired` on fields.
- Configuration via `@ConfigurationProperties` classes, not scattered
  `@Value` injections.
- Profiles (`application-<profile>.yml`) for environment-specific config.
- REST controllers: return `ResponseEntity<T>` or records, not raw
  `Map<String, Object>`.
- Validation: Jakarta Bean Validation (`@Valid`, `@NotNull`,
  `@Size`) on DTOs; custom validators as beans.

## Virtual threads (Project Loom)

Java 21+ has virtual threads:

- Use `Executors.newVirtualThreadPerTaskExecutor()` for I/O-bound work.
- Pinning: avoid `synchronized` blocks around blocking I/O — use
  `ReentrantLock` instead so virtual threads can unmount.
- Don't pool virtual threads. Their purpose is to be cheap to create.

## Polyglot path-scoping

```yaml
---
paths:
  - "**/*.java"
  - "**/pom.xml"
  - "**/build.gradle*"
  - "**/settings.gradle*"
  - "src/main/**"
  - "src/test/**"
---
```

## Example `.claude/rules/java.md` skeleton

```markdown
# Java

Applies to: Java sources under `src/main/java/` and tests under
`src/test/java/`.

## Defaults

- Java 21 LTS.
- Records for immutable data holders.
- Sealed interfaces + pattern matching for closed sums.
- Immutability by default: `final` fields, `List.copyOf` etc.

## Don'ts

- No checked exceptions in new code unless interface-mandated.
- No `Optional` in fields, parameters, or collections — return types only.
- No field or setter injection. Constructor injection only.
- No `System.out.println` in app code — use SLF4J.

## Pre-commit pipeline (Maven)

    ./mvnw spotless:apply
    ./mvnw checkstyle:check
    ./mvnw test

## Pre-commit pipeline (Gradle)

    ./gradlew spotlessApply
    ./gradlew check
    ./gradlew test

## Testing

- JUnit 5, AssertJ, Mockito (only when mocks are genuinely needed).
```
