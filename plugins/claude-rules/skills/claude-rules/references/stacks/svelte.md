# Svelte 5 conventions

Layer on top of `typescript.md` when the project is SvelteKit + TS (which
it almost always is for new work).

## Detection

| Signal                            | Meaning                                     |
| --------------------------------- | ------------------------------------------- |
| `svelte.config.*`                 | Svelte project                              |
| `svelte` in `package.json` (^5)   | Svelte 5 — runes available                  |
| `svelte` ^3 / ^4                  | Legacy — use stores, `$:` reactive blocks   |
| `@sveltejs/kit` in deps           | SvelteKit (full framework, preferred)       |
| `vite.config.*` + `svelte`        | Vite + Svelte (could be SvelteKit or bare)  |
| `src/routes/`                     | SvelteKit routing                           |
| `*.svelte` files                  | Svelte component files                      |
| `*.svelte.ts` / `*.svelte.js`     | Svelte 5 rune-using TS/JS modules           |

Check the `svelte` version — Svelte 5 is fundamentally different. If
`^3` or `^4`, don't suggest runes; they don't exist.

## Tooling

| Concern      | Command                                         |
| ------------ | ----------------------------------------------- |
| Dev          | `pnpm dev`                                      |
| Build        | `pnpm build`                                    |
| Preview      | `pnpm preview`                                  |
| Type check   | `pnpm check` (runs `svelte-check` + `tsc`)      |
| Lint         | `pnpm lint` (ESLint + `eslint-plugin-svelte` or Biome) |
| Format       | `pnpm format` (Prettier with `prettier-plugin-svelte`) |
| Test (unit)  | `pnpm vitest run`                               |
| Test (E2E)   | `pnpm playwright test`                          |

`svelte-check` is the non-negotiable gate — it type-checks `.svelte` files
which `tsc` alone can't see.

## Svelte 5 runes — the big rules

Target **Svelte 5 runes** for new projects. Mental model:

- **`$state(...)`** replaces `let x` for reactive variables. `$state` works
  in `.svelte` files and in `.svelte.ts` / `.svelte.js` modules (not in
  plain `.ts` / `.js`).
- **`$derived(...)`** replaces `$:` reactive statements for values.
  Preferred over `$effect` for computed values.
- **`$derived.by(() => { ... })`** for multi-line derivations.
- **`$effect(() => { ... })`** replaces `$:` for side effects. Run after
  the DOM updates.
- **`$props()`** replaces `export let` for component props. Returns an
  object you destructure: `let { title, onClick } = $props();`.
- **`$bindable()`** marks a prop as bindable (opt-in, unlike Svelte 4
  where `bind:` worked on anything exported).
- **No more stores for most cases.** `$state` at module scope (in a
  `.svelte.ts` file) replaces writable stores for shared state. Keep
  stores only for genuine subscription patterns or RxJS-like streams.
- **`$:` reactive blocks are legacy.** Don't write them in new Svelte 5
  code; the rune equivalents are clearer.

## Idiomatic rules to port / bootstrap

- Use runes. No `export let`, no `$:`, no `writable()`/`readable()` in
  new code.
- `.svelte.ts` for shared rune state; import and use directly, no
  `get(store)` ceremony.
- Props are destructured from `$props()` and typed inline:
  `let { title, count = 0 }: { title: string; count?: number } = $props();`
- Events: component events are just callback props. No `createEventDispatcher`
  — pass `onClick`, `onSubmit` as props.
- Slots → snippets in Svelte 5. Use `{#snippet name(args)}` + `{@render name(args)}`.
- `$effect` is a last resort. For derived values, use `$derived`. For
  DOM side effects tied to element lifecycle, prefer `onMount`-style via
  actions or attachment callbacks where possible.
- Run `pnpm check && pnpm lint && pnpm vitest run` before claiming done.
- SvelteKit: `+page.svelte` / `+layout.svelte` / `+page.server.ts` — use
  server load functions for server-only data fetching; client load
  functions for isomorphic.
- Form actions (`+page.server.ts` `actions` export) for mutations —
  Svelte's equivalent of Next.js server actions.
- Validate form input with Zod or valibot. Use `sveltekit-superforms` if
  the project already has it; otherwise roll your own.

## Testing

- Vitest + `@testing-library/svelte` for component tests.
- Playwright for E2E, tested against `pnpm preview` (production build).
- `vitest-environment-jsdom` or `happy-dom` for unit test DOM.

## Polyglot path-scoping

```yaml
---
paths:
  - "**/*.svelte"
  - "**/*.svelte.ts"
  - "**/*.svelte.js"
  - "src/routes/**"
  - "src/lib/**"
  - "svelte.config.*"
  - "vite.config.*"
---
```

## Example `.claude/rules/svelte.md` skeleton

```markdown
# Svelte 5 (SvelteKit)

Applies to: Svelte components under `src/` and SvelteKit routes under
`src/routes/`.

## Runes only

Use `$state`, `$derived`, `$effect`, `$props`, `$bindable`. No `export let`,
no `$:`, no `writable()`/`readable()` in new code.

## Props

Destructure from `$props()` with inline types:

    let { title, count = 0 }: { title: string; count?: number } = $props();

## Events

Component events are callback props. No `createEventDispatcher`.

## Shared state

`.svelte.ts` modules holding `$state` replace stores for most shared
state. Stores only for genuine subscription patterns.

## Pre-commit pipeline

    pnpm check        # svelte-check + tsc
    pnpm lint
    pnpm vitest run

## Forms (SvelteKit)

- `+page.server.ts` `actions` for mutations.
- Zod or valibot for validation.
- Progressive enhancement via `use:enhance` on `<form>`.
```
