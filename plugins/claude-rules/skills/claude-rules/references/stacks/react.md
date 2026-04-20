# React conventions

Layer this on top of `typescript.md` — everything in that file still
applies.

## Detection

| Signal                                         | Meaning                          |
| ---------------------------------------------- | -------------------------------- |
| `react` in `package.json` `dependencies`       | React is present                 |
| `@types/react`                                 | TypeScript + React               |
| `*.tsx` files                                  | TSX JSX surface                  |
| `react-dom` in deps                            | DOM target (not React Native)    |
| `react-native` in deps                         | React Native — different story   |
| Vite + `@vitejs/plugin-react`                  | Vite-based SPA                   |
| Next.js detected (`next.config.*`)             | Use `references/stacks/nextjs.md` instead |

## React 19 defaults

Target **React 19** for any new project unless the project is pinned
older. Key things 19 changed:

- `use` hook for awaiting promises or consuming context — works in server
  and client components.
- `forwardRef` no longer needed — `ref` is just a prop.
- `useTransition` returns `isPending` and an `action` — no more manual
  `startTransition` for most cases.
- Actions API: form `action` can be a function that runs server-side (when
  paired with a framework) or client-side.
- Compiler-ready: `React.memo`, `useCallback`, `useMemo` are often
  unnecessary if the React Compiler is enabled; don't add them reflexively.

## Idiomatic rules to port / bootstrap

- **Function components only.** No class components in new code.
- **Hooks rules**: call at the top level, same order every render. Enforce
  with `eslint-plugin-react-hooks`.
- **One hook per concern**: `useAuth`, `useCart`, `useTheme`. Don't
  inline `useEffect` + `useState` + fetch logic into component bodies.
- **Server state vs client state**: use TanStack Query / SWR for server
  state; local state with `useState` / `useReducer`. Don't sync server
  state into `useState`.
- **Forms**: React Hook Form or the Actions API + native form. Zod for
  validation. No hand-wired `onChange`-for-every-field for non-trivial
  forms.
- **Styling**: Tailwind is the default for new projects; scope with class
  merging (`clsx` / `tailwind-merge`). If the project uses CSS Modules
  or styled-components, don't mix in Tailwind halfway.
- **No `useCallback`/`useMemo` by default.** Add only when profiling
  shows a real regression. The React Compiler handles most of these.
- **Keys on lists**: stable, unique, derived from data. Not array index
  unless the list is genuinely static.
- **Effects as a last resort.** If you can derive the value during
  render or compute it from props/state, do that. `useEffect` is for
  subscribing to external systems, not reactive computation.
- **Accessibility**: every interactive element needs keyboard support,
  ARIA where structure alone isn't enough, and a visible focus ring.
  Enforce with `eslint-plugin-jsx-a11y`.

## Testing React

- **Vitest + React Testing Library** for unit/component tests.
- Test behavior, not implementation. `getByRole('button', { name: /save/ })`
  beats `getByTestId`.
- Mock at boundaries (`msw` for network), not internal hooks.
- `@testing-library/user-event` for interactions; don't fire events
  directly.

## React Native

If `react-native` is present, treat as a separate stack:
- Testing is Jest (not Vitest) by default.
- Platform files: `foo.ios.tsx` / `foo.android.tsx` for platform divergence.
- No direct DOM access; no `window` / `document`.
- Navigation via React Navigation or Expo Router.

## Polyglot path-scoping

```yaml
---
paths:
  - "**/*.tsx"
  - "**/components/**"
  - "**/pages/**"
  - "**/app/**"
  - "**/hooks/**"
---
```

## Example `.claude/rules/react.md` skeleton

```markdown
# React

Applies to: React 19 components and hooks under `src/`.

## Defaults

- Function components only. No classes.
- Tailwind for styling; `clsx` + `tailwind-merge` for conditional classes.
- TanStack Query for server state; `useState`/`useReducer` for local.

## Hooks

- Follow the rules of hooks (enforce with `eslint-plugin-react-hooks`).
- One hook per concern. Extract custom hooks for reuse.
- No `useCallback`/`useMemo` unless profiling shows a real regression.

## Effects

- Default to *not* using `useEffect`. Derive values during render.
- `useEffect` is only for subscribing to external systems (event
  listeners, intervals, WebSockets).

## Testing

- Vitest + React Testing Library.
- Query by role + accessible name. No `getByTestId` unless there is
  genuinely no accessible query.
- `msw` for network mocks; no internal-hook mocking.
```
