---
name: docker-ci
description: >-
  Dockerfiles (multi-stage, non-root), docker-compose for local dependencies,
  .dockerignore, healthchecks and CI pipelines (GitHub Actions: lint, typecheck,
  test, build, deploy gates). Triggers: Dockerfile, compose, container, CI,
  pipeline, workflow yaml, build fails in CI.
---

Goal: the same build runs anywhere, and every change is verified automatically before merge.

## Dockerfile rules

- Multi-stage: `deps` (lockfile install) → `build` → `runtime` with only prod deps and build output.
- Base image pinned (major, or digest for prod) and matching `.nvmrc`/`engines`.
- Copy the lockfile before the source so dependency layers cache; `npm ci` / `pnpm install --frozen-lockfile` / `yarn --immutable`.
- Runtime runs as non-root (`USER node`); `CMD ["node", "dist/main.js"]` (via `tini`), not `npm start`, so SIGTERM reaches the app.
- No secrets in `ENV`, `ARG` or copied files; build-time tokens via `--mount=type=secret`.
- `.dockerignore`: `node_modules`, `dist`, `.git`, `.env*`, `coverage`, `workflow/`, `*.log`.
- `HEALTHCHECK` hits `/health`; add `/ready` when the app depends on a DB.
- SPA: static files served by nginx/caddy with SPA fallback. Nuxt SSR: `node .output/server/index.mjs`.

## docker-compose (dev only)

- Compose runs the **dependencies** (Postgres, Redis, Mailpit). Images pinned (no `latest`), `healthcheck`s, `depends_on: condition: service_healthy`.
- Ports bound to `127.0.0.1`; named volumes; throwaway credentials from `.env`.

## CI rules (GitHub Actions default)

Order, cheapest first: install (lockfile + cache) → lint → typecheck → unit tests → integration tests against `services:` with migrations applied → build → `npm audit --audit-level=high` → publish/deploy only on `main`/tags behind `environment:` protection.

```yaml
name: ci
on: { pull_request: {}, push: { branches: [main] } }
concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true
permissions: { contents: read }
jobs:
  verify:
    runs-on: ubuntu-latest
    timeout-minutes: 15
    services:
      postgres:
        image: postgres:17-alpine
        env: { POSTGRES_PASSWORD: postgres, POSTGRES_DB: app_test }
        ports: ['5432:5432']
        options: --health-cmd "pg_isready -U postgres" --health-interval 5s --health-retries 10
    env: { DATABASE_URL: postgresql://postgres:postgres@localhost:5432/app_test }
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci
      - run: npm run lint
      - run: npm run typecheck
      - run: npm run db:migrate:deploy
      - run: npm test -- --ci
      - run: npm run build
```

- Least-privilege `permissions:`; extra scopes only on the job that needs them.
- Third-party actions pinned to a major tag, or a commit SHA if not official.
- Secrets only via `secrets.*`/environments; never run fork code with secrets (`pull_request_target` + PR checkout is forbidden).
- CI calls `package.json` scripts so developers run the same commands locally.
- Flaky tests get fixed or quarantined with an issue, never silently retried.
- Registry credentials, deploy keys, repository secrets and branch protection are set by a person: create a manual task listing each one.

## Checklist

- [ ] Multi-stage, pinned, lockfile install, non-root, no secrets in layers, `.dockerignore`.
- [ ] Healthcheck wired.
- [ ] Compose pinned, healthchecked, bound to localhost.
- [ ] CI: install → lint → typecheck → test → build, with cache, timeouts, least privilege.
- [ ] Deploy gated; manual task for required secrets.

## Out of scope

- Env schema and `.env.example` → `env-config`. Writing migrations → `database-persistence`.
- Commit/PR format → `commit-pr-conventions`. App security controls → `secure-coding`.
