---
name: performance
description: >-
  Make code faster or lighter, measuring before and after: Core Web Vitals
  (LCP, INP, CLS), bundle size, lazy loading, render cost, Node event-loop
  blocking, caching, timeouts, latency. Triggers: slow, optimize, Lighthouse,
  bundle size, re-render, p95, memory leak, profiling.
---

## The rule: measure, change one thing, measure again

1. State the target in user terms ("list LCP < 2.5s on mobile", "`GET /orders` p95 < 200ms at 50 rps").
2. Measure the baseline in prod-like conditions: prod build, throttled CPU/network, realistic data volume.
3. Profile to find the bottleneck; don't guess.
4. Fix the biggest cause, re-measure, stop at the target. Don't trade readability for gains nobody notices.
5. Write before/after numbers in the task/step summary. Record non-obvious findings in `workflow/project-memory.md`; budgets (e.g. max dependency size) via `adr-decisions`.

## Tools

- **Frontend:** Lighthouse/PageSpeed (lab), `web-vitals` or RUM (field), DevTools Performance, bundle analyzer (`vite-bundle-visualizer`, `nuxi analyze`), React Profiler / Vue DevTools.
- **Backend:** `autocannon`/`k6` (load), `clinic flame` / `--cpu-prof` (CPU), heap snapshots (memory), `EXPLAIN ANALYZE`, request duration from the request-id logger.

## Project defaults (not optional)

**Frontend** (targets p75 mobile: LCP ≤ 2.5s · INP ≤ 200ms · CLS ≤ 0.1)
- The LCP image is never lazy: `fetchpriority="high"`, sized `srcset`, AVIF/WebP (`@nuxt/image`/`next/image` when available).
- Every image/embed has `width`/`height` or `aspect-ratio`; skeletons match content size.
- Route-level code splitting; heavy below-the-fold components (charts, editors, maps) lazy-loaded.
- Check a dependency's gzipped cost before adding it; prefer native APIs.
- Lists over ~200 rows are virtualized; list `key`s are stable ids.
- Fix re-renders at the source (state placement, store selectors) before adding `memo`/`useMemo`.

**Backend (Node)**
- No sync FS/crypto or CPU-heavy loops on the request path; use a worker thread or a queue.
- Independent I/O in parallel (`Promise.all`) with bounded fan-out (`p-limit`).
- Caches state what, where, TTL and **invalidation**; keys include every input that changes the result (tenant, locale, user).
- Timeouts on outbound HTTP and DB statements; body size limits.
- Slow side work (emails, images, reports) goes to background jobs and the API answers `202`.
- No unbounded in-memory maps; listeners and intervals cleaned up.

## Checklist

- [ ] Baseline and after numbers recorded under the same conditions.
- [ ] Change targets the measured bottleneck.
- [ ] Frontend and backend defaults above hold for the touched code.
- [ ] Any non-obvious optimization has a one-line comment with the measured reason.

## Out of scope

- Indexes, query plans, N+1, pooling → `database-persistence`.
- Nuxt rendering modes, `routeRules`, payload trimming → `nuxt-4-dev`.
- Client cache `staleTime` policy → `state-management`.
- Rate limiting as a security control → `secure-coding`.
