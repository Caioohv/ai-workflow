---
name: nuxt-development
description: Build, review, and refactor Nuxt applications following the framework's own documented conventions. Use this skill whenever the user is writing Nuxt/Vue meta-framework code, structuring a Nuxt project, choosing a data-fetching or rendering strategy, wiring server routes (Nitro), managing SSR-safe state, or debugging hydration/double-fetch/state-leak issues, even if they don't explicitly say "Nuxt best practices". Targets Nuxt 4 (app/ directory, shared data fetching, stricter TS) and flags Nuxt 3 differences where relevant.
---

# Nuxt Development

Guide for producing idiomatic Nuxt 4 code. The core principle: Nuxt is an SSR-first framework, so almost every bug that looks weird (double requests, state leaking between users, `window is not defined`, hydration mismatch) comes from writing client-only patterns in a universal runtime. Default to the framework's composables instead of hand-rolling.

Assume Nuxt 4 unless the project's `nuxt.config.ts` or `package.json` says otherwise. Nuxt 3 reaches end of life on 31 July 2026; new projects should not start on 3.

## Project structure (Nuxt 4)

Application code lives under `app/`, separated from config and `node_modules/` at the root. Respect the convention-based directories instead of inventing your own layout:

- `app/pages/` file-based routes (typed routes are on by default in 4)
- `app/components/` auto-imported, no manual `import`
- `app/composables/` and `app/utils/` auto-imported top-level exports
- `app/layouts/`, `app/middleware/`, `app/plugins/`
- `server/` Nitro backend: `server/api/`, `server/routes/`, `server/middleware/`, `server/utils/`
- `shared/` code usable by both app and server (Nuxt 4)
- `public/` served as-is; `assets/` processed by the bundler

Do not fight auto-imports by adding explicit imports for composables/components. If a symbol isn't resolving, the fix is directory placement or `nuxt.config`, not a manual import.

## Data fetching (the highest-leverage decision)

Pick the tool by intent, not by habit:

- `useFetch(url, opts)` component-level SSR data. Runs on server during SSR, serializes the result into the payload, and does NOT refetch on the client during hydration. This is the default for "load data to render this page/component".
- `useAsyncData(key, fn, opts)` same guarantees as `useFetch` but you control the fetching function. Use when the source isn't a single URL (multiple calls, a DB/ORM call inside `server/`, an SDK).
- `$fetch(url)` the raw call. Use for client-side actions triggered by user events (form submit, button click, mutations). Do NOT call bare `$fetch` at setup top-level for initial data: it runs on both server and client, double-fetching and skipping payload transfer.

Rule of thumb: **rendering data → `useFetch`/`useAsyncData`; user-triggered actions → `$fetch`.**

Documented behaviors to rely on (Nuxt 4):
- Calls sharing the same `key` share one `data`/`error`/`status` ref, dedupe in flight, and clean up on unmount. Reuse keys deliberately to share; use distinct keys to isolate.
- `useAsyncData` supports an `AbortController` signal for cancellation (`(_ctx, { signal }) => $fetch(url, { signal })`).

Always trim the payload and control timing:
- `pick` / `transform` to strip fields you won't render, so they don't ship in the HTML payload.
- `lazy: true` (or `useLazyFetch`) to not block navigation on slow calls; pair with a pending/skeleton state.
- `server: false` for data that must only run client-side (per-user, non-SSR, browser-only APIs).
- `watch` / reactive URL (a `computed`/ref in the URL) for dependent or refetch-on-change queries; use `refresh()` for manual refetch.
- For repeated setups (auth headers, base URL, error normalization), build a custom `useFetch` factory via `$fetch.create` and export it as a composable, rather than repeating options everywhere.

## Rendering strategy and route rules

Nuxt renders SSR by default. Choose per-route with `routeRules` in `nuxt.config.ts` (hybrid rendering) instead of forcing one mode globally:

```ts
export default defineNuxtConfig({
  routeRules: {
    '/':            { prerender: true },          // static at build
    '/blog/**':     { swr: 3600 },                // stale-while-revalidate cache
    '/products/**': { isr: true },                // incremental static regen
    '/admin/**':    { ssr: false },               // SPA-only, no SSR
    '/api/legacy':  { proxy: 'https://old.example.com' },
  },
})
```

Guidance: prerender anything static (marketing, docs), SWR/ISR for content that changes on a cadence, `ssr: false` only for authenticated/interactive dashboards where SEO doesn't matter. Cache at the edge/Nitro layer before optimizing app code.

## SSR-safe state

Never use a module-scope `ref`/`reactive` for shared state on the server: it's a singleton shared across all requests, so one user's data leaks into another's. Use `useState(key, init)` for cross-component SSR-safe state, or a store (Pinia) that Nuxt sets up per-request.

Anything that touches `window`, `document`, `localStorage`, or `navigator` must be guarded by `import.meta.client` or run inside `onMounted`/`server: false`, or it breaks SSR.

## Server / Nitro

Backend logic goes in `server/`. Define handlers with `defineEventHandler`; read input with `getQuery`, `readBody`, `getRouterParam`; throw `createError({ statusCode, statusMessage })` for typed errors. Keep secrets out of client bundles: put them in `runtimeConfig` (server-only) and expose only what's needed under `runtimeConfig.public`. Never read `process.env` directly in components.

Return typed responses from `server/api/` handlers so `useFetch` infers end-to-end types on the client. This is a real Nuxt 4 selling point; don't erase it with `any` or untyped `$fetch`.

## Performance defaults

- Lazy-load below-the-fold components with the `Lazy` prefix (`<LazyHeavyChart />`).
- Use `@nuxt/image` (`<NuxtImg>` / `<NuxtPicture>`) for sizing, formats, and lazy loading instead of raw `<img>`.
- Trim SSR payload with `pick`/`transform` (see fetching section) and prefer `shallowRef` for large non-deeply-reactive data (Nuxt 4 leans on shallow reactivity by default).
- Use `<NuxtLink>` for internal navigation to get prefetching.
- Reach for official/community modules before hand-rolling: `@nuxt/image`, `@nuxtjs/i18n`, `@vueuse/nuxt`, `@nuxt/fonts`, `@pinia/nuxt`. Modules integrate with the build; ad-hoc plugins often don't.

## TypeScript

Nuxt 4 uses separate TS projects (app vs server) and is stricter than 3. Fix type errors rather than suppressing them; a "new" error after upgrading is usually a real one Nuxt 3 tolerated. Prefer typed route params and typed `runtimeConfig`.

## Common failure modes to check in review

- Bare `$fetch` at setup top-level for page data → double fetch, no payload. Switch to `useFetch`.
- Module-scope `ref` for shared state → cross-request leak. Switch to `useState`.
- Browser API at top-level of `<script setup>` → SSR crash. Guard with `import.meta.client`/`onMounted`.
- Same-key `useFetch` in two components expecting independent data → they now share refs in Nuxt 4. Give distinct keys.
- Secrets in `runtimeConfig.public` or read from `process.env` in components → leaked to client bundle.
- Global SSR forced off to "fix" a browser error → lost SEO/perf. Fix the guard, keep SSR.

## When unsure

Prefer the framework's documented composable over a custom solution, and confirm current behavior against the Nuxt docs (data fetching and rendering pages change between minor releases). If the project is on Nuxt 3, keep the same principles but expect the flat root structure, no `app/` dir, and non-shared fetch refs unless the 3.x minor backported it.