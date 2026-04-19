---
name: vite-chunk-split
description: >
  Fix Vite single-chunk bundles that cause slow page loads and break MCP Playwright testing.
  Auto-detects heavy dependencies, converts static page imports to React.lazy, adds Suspense
  boundaries in layout components, and configures vendor chunk splitting in vite.config.ts.
  Use when a Vite + React SPA ships everything in one JS chunk, when MCP Playwright times out
  on navigation or snapshots, when build output shows a single chunk over 500KB, or when pages
  load libraries they don't use. Also applies to Vue/Svelte projects with Vite — adapt the
  lazy-loading syntax to the framework's equivalent (defineAsyncComponent, dynamic import).
---

# Vite Chunk Split

Fix single-chunk Vite builds that force browsers to parse the entire application on every page load. This causes slow initial renders and makes MCP Playwright unreliable (timeouts on navigate, stale snapshots, failed interactions).

## When to Use

- Build output has a single JS chunk over 500KB
- MCP Playwright times out on `browser_navigate` or `browser_snapshot`
- Pages load heavy libraries they don't use (ReactFlow on a settings page, CodeMirror on a dashboard)
- `vite build` warns about chunk size but no `manualChunks` is configured

## Diagnosis

Before making changes, measure the current state:

```bash
# Check current chunk distribution
ls -lhS <project>/dist/assets/*.js

# Look for the single-chunk pattern:
# - One file over 500KB (the monolith)
# - Maybe one framework chunk (react-vendor or similar)
# - Everything else is tiny or absent
```

If the largest chunk contains both application code AND vendor libraries, this skill applies.

## Step 1 — Identify the Router and Page Imports

Find the file that defines routes and imports all page components. Common locations:

- `src/main.tsx` or `src/App.tsx` (React Router)
- `src/router.ts` or `src/router/index.ts` (Vue Router)
- `src/routes/+layout.ts` (SvelteKit — already lazy by default)

Read the file. Count the static page imports. Each one pulls its entire dependency tree into the main chunk.

## Step 2 — Identify Heavy Dependencies

Check `package.json` for known-heavy libraries:

| Library | Typical Size | Only Needed On |
|---------|-------------|----------------|
| `monaco-editor` | 2-4MB | Code editor pages |
| `react-syntax-highlighter` + prism | ~650KB | Code display pages |
| `@codemirror/*` | ~400KB | Code editor pages |
| `@mui/material` or `antd` | 200-500KB | Depends on usage |
| `recharts` / `chart.js` + d3 | 50-200KB | Dashboard/analytics |
| `react-diff-viewer` | ~180KB | Diff/compare pages |
| `@xyflow/react` + dagre | ~90KB | Graph/flow pages |
| `marked` / `markdown-it` + DOMPurify | ~60KB | Markdown preview pages |
| `react-image-crop` | ~15KB | Image editor pages |

Map each heavy dependency to the page(s) that actually use it.

## Step 3 — Convert Static Imports to Lazy

Replace every page import in the router file with `React.lazy`:

```tsx
// Before — entire dep tree lands in main chunk
import { MyPage } from './pages/MyPage'

// After — separate chunk loaded on navigation
const MyPage = lazy(() =>
  import('./pages/MyPage').then((m) => ({ default: m.MyPage }))
)
```

If the page uses `export default`:
```tsx
const MyPage = lazy(() => import('./pages/MyPage'))
```

**Keep layout components static.** Any component that renders `<Outlet />` (React Router), `<RouterView />` (Vue Router), or `<slot />` (Svelte) must stay as a static import so the shell never flashes.

### Vue equivalent

```ts
const MyPage = defineAsyncComponent(() => import('./pages/MyPage.vue'))
```

### SvelteKit

SvelteKit already lazy-loads routes by default. No changes needed unless you have eagerly-imported heavy components inside pages.

## Step 4 — Add Suspense Boundaries

Wrap `<Outlet />` in each layout component with `<Suspense>`:

```tsx
import { Suspense } from 'react'

// In the layout component:
<Suspense fallback={<div className="loading">Loading…</div>}>
  <Outlet />
</Suspense>
```

Place Suspense **inside layouts, not at the router root**. The sidebar, header, and navigation tabs must stay visible while page chunks load.

If the project has nested layouts (e.g., a dashboard layout inside the app layout), add Suspense to each one that wraps an `<Outlet />`.

### Vue equivalent

```vue
<Suspense>
  <RouterView />
  <template #fallback>
    <div class="loading">Loading…</div>
  </template>
</Suspense>
```

## Step 5 — Configure Vendor Chunk Splitting

Add `manualChunks` to `vite.config.ts`:

```ts
build: {
  chunkSizeWarningLimit: 700,
  rollupOptions: {
    output: {
      manualChunks(id) {
        if (!id.includes('node_modules')) return

        // React core — loaded on every page
        if (id.includes('/react/') || id.includes('/react-dom/') || id.includes('/scheduler/'))
          return 'vendor-react'

        // Add entries for each heavy dependency group identified in Step 2.
        // Pattern: check id.includes('package-name'), return a chunk name.
        //
        // Examples (uncomment and adjust based on package.json):
        // if (id.includes('@xyflow/') || id.includes('dagre')) return 'vendor-reactflow'
        // if (id.includes('@codemirror/') || id.includes('@lezer/')) return 'vendor-codemirror'
        // if (id.includes('monaco-editor')) return 'vendor-monaco'
        // if (id.includes('recharts') || id.includes('/d3-')) return 'vendor-charts'
        // if (id.includes('react-diff-viewer') || id.includes('/diff/')) return 'vendor-diff'
        // if (id.includes('marked') || id.includes('dompurify')) return 'vendor-markdown'
        // if (id.includes('react-syntax-highlighter') || id.includes('prismjs')) return 'vendor-syntax'
        // if (id.includes('@mui/')) return 'vendor-mui'
        // if (id.includes('@radix-ui/')) return 'vendor-radix'
        // if (id.includes('react-image-crop')) return 'vendor-media'
      },
    },
  },
},
```

**Rules for manualChunks:**
- Only split `node_modules` — application code splits naturally via lazy imports
- Group by consumer page, not by package name — if two packages are always used together, put them in one chunk
- React core goes in `vendor-react` — it's needed everywhere
- Router goes in its own chunk or with React — also needed everywhere
- Everything else should only load when its page is visited

## Step 6 — Verify

```bash
# Build and check output
npx vite build  # or pnpm run build

# Verify:
# 1. No single chunk over 500KB (except vendor-react which is unavoidable)
# 2. App shell (index/main) is under 50KB
# 3. Page chunks are small (2-50KB each)
# 4. Heavy vendor chunks are isolated
# 5. Each vendor chunk name maps to a clear consumer

# Check total file count increased significantly
ls dist/assets/*.js | wc -l
# Before: 3-5 files
# After: 20-50 files (depends on page count)
```

Then test with MCP Playwright — navigation should be responsive on all pages.

## What NOT to Do

- **Don't lazy-load layout components** — the shell must render immediately
- **Don't put Suspense at the router root** — it blanks the entire screen during chunk loads
- **Don't split application code with manualChunks** — let Vite handle that via the lazy imports
- **Don't create one chunk per node_module** — group by consumer page for better caching
- **Don't forget to add Suspense** — lazy components without Suspense crash with "A component suspended while responding to synchronous input"
