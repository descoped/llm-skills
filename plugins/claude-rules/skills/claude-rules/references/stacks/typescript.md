# TypeScript conventions (base)

Base rules for any TypeScript project. Framework-specific references
(React, Next.js, Svelte) layer on top — read both when the target uses
one.

## Detection

| Signal                                      | Meaning                                   |
| ------------------------------------------- | ----------------------------------------- |
| `tsconfig.json`                             | TypeScript project                        |
| `package.json` with `"type": "module"`      | Modern ESM (preferred)                    |
| `pnpm-lock.yaml` / `bun.lockb` / `yarn.lock` / `package-lock.json` | Pkg manager (pnpm >> bun > yarn > npm in modern work) |
| `biome.json` / `biome.jsonc`                | Biome for format+lint                     |
| `eslint.config.*` (flat config) / `.eslintrc.*` (legacy) | ESLint              |
| `.prettierrc.*`                             | Prettier                                  |
| `vitest.config.*`                           | Vitest                                    |
| `jest.config.*`                             | Jest (legacy-ish for new projects)        |

## Tooling

Prefer **pnpm + Biome (or ESLint+Prettier) + tsc --noEmit + Vitest**.

| Concern       | Command                                              |
| ------------- | ---------------------------------------------------- |
| Install       | `pnpm install`                                       |
| Format        | `pnpm biome format --write .` or `pnpm prettier --write .` |
| Lint          | `pnpm biome check --write .` or `pnpm eslint . --fix`      |
| Type check    | `pnpm tsc --noEmit`                                  |
| Test          | `pnpm vitest run` (or `pnpm test`)                   |
| Build         | `pnpm build` (delegates to bundler — vite, tsup, etc.) |

Biome consolidates format + lint in a single fast tool — prefer it for
new projects. ESLint + Prettier is fine but slower.

## Idiomatic rules to port / bootstrap

- Run `pnpm biome check --write . && pnpm tsc --noEmit && pnpm vitest run` before claiming done (swap Biome for ESLint+Prettier if that's the chosen stack).
- Strict mode: `tsconfig.json` should have `"strict": true`, `"noUncheckedIndexedAccess": true`, `"exactOptionalPropertyTypes": true`. Don't weaken these.
- No `any`. Use `unknown` and narrow, or define a proper type. `eslint` rule `@typescript-eslint/no-explicit-any` should be on.
- Don't export barrels (`index.ts` re-exporting everything) — they break tree-shaking and make cyclic imports easier. Import from the real file.
- Use `satisfies` for literal validation without widening (`const config = { ... } satisfies Config`).
- Prefer `type` over `interface` unless you specifically need interface merging or class `implements`.
- ESM only for new projects. No `require()`. Use `.js` extensions in import specifiers if `moduleResolution` is `nodenext`/`node16`.
- Validate boundary input with Zod / valibot; derive types with `z.infer`/`v.InferOutput` rather than hand-writing parallel types.
- No `console.log` in committed code. Use a proper logger (`pino`, `consola`) or delete the line.
- Tests: one behavior per `test()` / `it()`; mock only at boundaries (network, fs), not internal collaborators.

## Module boundaries

- Package exports: declare `"exports"` in `package.json` for any published package — don't let consumers reach into subpaths.
- Monorepo workspaces: use pnpm workspaces or Turborepo. Inter-package imports go through published package names (e.g., `@scope/ui`), not relative paths.

## Polyglot path-scoping

```yaml
---
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.mts"
  - "**/*.cts"
  - "**/tsconfig*.json"
  - "**/package.json"
  - "**/pnpm-lock.yaml"
---
```

If the target splits TS into multiple packages, scope tighter:

```yaml
paths:
  - "packages/web/**"
  - "packages/api/**"
```

## Example `.claude/rules/typescript.md` skeleton

```markdown
# TypeScript

Applies to: TS/TSX packages under `packages/`.

## Pre-commit pipeline

    pnpm biome check --write .
    pnpm tsc --noEmit
    pnpm vitest run

## Strictness

`tsconfig.json` must keep: `strict: true`, `noUncheckedIndexedAccess: true`,
`exactOptionalPropertyTypes: true`. No weakening.

## Conventions

- No `any`. Use `unknown` and narrow.
- `type` over `interface` by default.
- No barrel exports. Import from the real file.
- Validate boundary input with Zod; derive types with `z.infer`.
- No `console.log` in committed code.
```
