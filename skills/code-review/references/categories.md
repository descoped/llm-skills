# Clean Code Categories

Seven universal categories for code quality analysis. Each category includes tech-specific variants — include only those matching the target project's tech stacks.

## 1. Single Responsibility Principle (SRP)

A function, type, or module should have one reason to change.

**What to look for:**

- Functions doing multiple unrelated things (fetch + transform + persist in one function)
- Types with mixed concerns (a struct that's both a domain model and a DTO)
- Modules mixing abstraction levels (parsing next to business rules)
- God objects — types or components doing everything

Tech-specific:

- **[rust/go/java/python]** Route handlers or API endpoints containing business logic instead of delegating to services
- **[rust]** Structs with >10 fields or >8 methods
- **[react/svelte/nextjs]** Components doing data fetching + business logic + rendering in one body
- **[react/svelte]** Components with >200 lines
- **[swift]** View bodies mixing business logic with SwiftUI layout

**How to report:**
> `file:line` — `FunctionOrType`: does X, Y, and Z. Split into [suggestion].

---

## 2. Don't Repeat Yourself (DRY)

Every piece of knowledge should have a single, unambiguous representation.

**What to look for:**

- Copy-pasted code blocks (same logic in multiple handlers, views, or adapters)
- Repeated patterns that differ only in type name or field (pagination, error mapping, CRUD boilerplate)
- Duplicated constants or magic numbers across files
- Similar types that could share a common base or generic

Tech-specific:

- **[rust]** Identical match arms across multiple functions
- **[go]** Repeated error handling boilerplate (`if err != nil { return err }` with identical wrapping)
- **[react/svelte]** Duplicated style objects, identical component patterns across pages
- **[python]** Repeated decorator stacks or identical try/except blocks

**How to report:**
> Pattern `X` is duplicated in `file1:line`, `file2:line`, `file3:line`. Extract to [shared location].

---

## 3. Dead Code & Orphans

Code that is never called, never reachable, or no longer needed.

**What to look for:**

- Unused functions, methods, types, traits, enums, or enum variants
- Unused imports
- Unreachable match arms, if-branches, or switch cases
- Commented-out code blocks left behind
- Files that nothing imports or references
- Public API surface that has no external consumers

Tech-specific:

- **[rust]** `#[allow(unused)]` hiding real dead code; feature-gated code where the feature is never enabled
- **[typescript]** Unused CSS classes in global stylesheets; unused exports
- **[python]** `__all__` exports with no consumers; unreachable code after early returns
- **[swift]** `#if` blocks for removed feature flags
- **[go]** Unexported functions with no callers in the package

**How to report:**
> `file:line` — `symbol_name` is never referenced. Safe to remove. (Verified: searched all call sites.)

---

## 4. Stubs & Incomplete Code

Placeholder implementations that were never finished.

**What to look for:**

- `TODO`, `FIXME`, `HACK`, `XXX`, `TEMP`, `STUB` comments
- Empty function/method bodies or bodies that just return a default/placeholder
- Empty catch/except blocks that swallow errors silently
- Functions that always return hardcoded values or empty collections
- Commented-out parameters or arguments

Tech-specific stub markers:

- **[rust]** `unimplemented!()`, `todo!()`, `panic!("not implemented")`
- **[python]** `pass` bodies, `raise NotImplementedError`
- **[go]** `panic("not implemented")`, `// TODO` with empty function body
- **[java/kotlin]** `throw new UnsupportedOperationException()`
- **[swift]** `fatalError("not implemented")`
- **[typescript]** `throw new Error("not implemented")`

**How to report:**
> `file:line` — `function_name`: stub/TODO found. Status: [likely forgotten | intentional placeholder | blocking on X].

---

## 5. Complexity

Code that is harder to understand, test, or modify than necessary.

### Thresholds by tech

| Metric | Rust | Python | Go | Java | TypeScript | Swift | Svelte component |
|--------|------|--------|----|------|------------|-------|------------------|
| Long function | >40 lines | >30 lines | >40 lines | >30 lines | >30 lines | >30 lines | >30 lines |
| Deep nesting | >3 levels | >3 levels | >3 levels | >3 levels | >3 levels | >3 levels | >3 levels |
| Too many params | >4 | >5 | >4 | >5 | >5 props | >5 | >5 props |
| Long file | >500 lines | >400 lines | >400 lines | >400 lines | >300 lines | >300 lines | >200 lines |

**What to look for (universal):**

- Complex conditionals: boolean expressions with >3 terms — extract to named function
- Long match/switch chains: >6 arms/cases — consider a lookup table or dispatch
- Primitive obsession: using String/int where a newtype, enum, or typed wrapper would add safety

**How to report:**
> `file:line` — `function_name`: [metric] (e.g., 67 lines, 5 nesting levels, 7 parameters). Simplify by [suggestion].

---

## 6. Coupling & Cohesion

Modules should be loosely coupled (few external dependencies) and highly cohesive (everything inside belongs together).

**What to look for:**

- **Tight coupling**: Module A directly constructs or calls internals of Module B instead of using an interface/trait/protocol
- **Circular dependencies**: A depends on B depends on A
- **Feature envy**: A function that uses more data from another module than its own
- **Inappropriate intimacy**: Reaching into another module's private details
- **Shotgun surgery**: Changing one concept requires touching >3 files
- **Low cohesion**: A module containing unrelated functions/types that don't interact
- **Leaky abstractions**: Implementation details exposed in public interfaces

Tech-specific:

- **[rust/go/java]** Module calling internals instead of using interface/trait/port
- **[hexagonal]** Core importing infrastructure types (database, HTTP, etc.)
- **[layered]** Lower layer importing from upper layer
- **[react/svelte]** Component importing from another component's internal files
- **[nextjs]** Client component doing server work or server component using client hooks
- **[swift]** View directly accessing persistence layer instead of going through service

**How to report:**
> `module_a` is tightly coupled to `module_b` via [specific dependency]. Decouple by [suggestion].

---

## 7. Naming & Clarity

Code should read like well-written prose. Names should reveal intent.

**What to look for:**

- Single-letter variables outside of closures/iterators (`x`, `s`, `v` as function params)
- Misleading names (function named `get_X` that also modifies state)
- Inconsistent naming (same concept called `item` in one place and `entry` in another)
- Generic names that don't convey purpose (`data`, `result`, `value`, `info`, `temp`, `helper`, `utils`)
- Type names that don't match their role (a service called `Manager`, a DTO called `Model`)

Tech-specific:

- **[rust/python/go]** Boolean variables/functions without `is_`/`has_`/`can_`/`should_` prefix
- **[typescript/swift]** Boolean without `is`/`has`/`can`/`should` prefix
- **[rust]** Abbreviated names where full word is clearer (`cfg` vs `config`, `mgr` vs `manager`)

**How to report:**
> `file:line` — `old_name`: rename to `suggested_name` for clarity. Reason: [why current name is misleading/unclear].
