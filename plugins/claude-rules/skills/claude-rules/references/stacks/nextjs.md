# Next.js conventions

Layer this on top of `typescript.md` and `react.md` — both still apply.

## Detection

| Signal                             | Meaning                                |
| ---------------------------------- | -------------------------------------- |
| `next.config.*`                    | Next.js project                        |
| `app/` directory                   | App Router (modern, preferred)         |
| `pages/` directory                 | Pages Router (legacy for new work)     |
| Both `app/` and `pages/`           | Migrating — App Router takes priority  |
| `middleware.ts` at repo root       | Edge middleware in use                 |
| `next` version in `package.json`   | Check for ≥ 15 (stable RSC)            |

## Tooling

| Concern     | Command                                   |
| ----------- | ----------------------------------------- |
| Dev         | `pnpm dev` (next dev, often with Turbopack) |
| Build       | `pnpm build`                              |
| Start       | `pnpm start`                              |
| Lint        | `pnpm next lint` (or Biome if configured) |
| Type check  | `pnpm tsc --noEmit`                       |
| Test        | `pnpm vitest run` (or Playwright for E2E) |

## App Router defaults

Target **App Router** for new projects. Mental model:

- **Server components** by default. They run on the server, render to
  HTML, and do not ship their JS to the browser. Use for data fetching,
  heavy trees, anything that can be static.
- **Client components** are opt-in with `"use client"` at the top. Use
  when you need state, effects, event handlers, or browser-only APIs.
- **Keep `"use client"` as leafy as possible.** A `"use client"` boundary
  pulls everything it imports into the client bundle.
- **Server actions** (`"use server"`) for mutations. Prefer over
  `/api/<route>/route.ts` for app-internal mutations.
- **Data fetching** in server components: use plain `fetch` with
  Next.js's cache/revalidate options, or a typed DB client. TanStack
  Query is for client components only.
- **Streaming**: use `loading.tsx` for route-level loading, `<Suspense>`
  for sub-route boundaries.

## Idiomatic rules to port / bootstrap

- Server components by default; `"use client"` is opt-in, kept leafy.
- `app/<route>/page.tsx` for pages; `layout.tsx` for shared shells;
  `loading.tsx` and `error.tsx` per segment.
- Dynamic route params: `page.tsx` receives `params` and `searchParams`
  — both are typed as `Promise<...>` in Next 15+.
- Server actions are typed. Validate input with Zod inside the action
  function body, not via framework glue.
- Use `next/image`, `next/font/local`, `next/link` — don't reach for raw
  `<img>`, `<a>`, or font imports.
- Metadata via the `generateMetadata` export, not manual `<head>` tags.
- Env vars: `NEXT_PUBLIC_*` only for values genuinely safe in the
  browser. Never prefix secrets.
- Route handlers (`app/api/<route>/route.ts`) are for external HTTP APIs
  (webhooks, third-party integrations). Don't use them for internal
  mutations — that's what server actions are for.

## Auth patterns

- Middleware for edge-level redirects (not session checks that need a DB).
- Session lookup in server components via a typed `auth()` helper that
  returns user or null — don't leak session tokens to client components.
- If using NextAuth / Auth.js, keep the session-fetching helper in a
  single server-only module.

## Testing

- **Unit/component**: Vitest + React Testing Library, same as React base.
- **Server components + data fetching**: Playwright E2E is often
  easier than trying to unit-test RSC trees.
- **Server actions**: test as plain async functions — they're just
  exported functions the framework happens to call.

## Polyglot path-scoping

```yaml
---
paths:
  - "app/**"
  - "pages/**"
  - "middleware.ts"
  - "next.config.*"
  - "**/*.tsx"
---
```

## Example `.claude/rules/nextjs.md` skeleton

```markdown
# Next.js (App Router, ≥ v15)

Applies to: Next.js app under `app/`.

## Defaults

- Server components by default. `"use client"` is opt-in, kept leafy.
- Server actions for mutations. Route handlers only for external APIs
  (webhooks, integrations).
- `next/image`, `next/font`, `next/link` — never raw `<img>` or `<a>`.
- Metadata via `generateMetadata`.

## Dynamic params

`page.tsx` receives `params: Promise<{ id: string }>` and
`searchParams: Promise<{ ... }>`. Await them.

## Env vars

- `NEXT_PUBLIC_*` only for values genuinely safe in the browser.
- Secrets: server-only, never `NEXT_PUBLIC_`.

## Data fetching

- Server components: `fetch` with cache/revalidate options, or a typed
  DB client.
- Client components: TanStack Query or SWR.

## Testing

- Unit: Vitest + RTL.
- E2E: Playwright against `pnpm start`.
```
