---
name: env-config
description: >-
  Environment variables and config in Node/TS apps: one typed config module
  validated at boot, .env.example, secrets vs config, public vs server-only
  vars (Nuxt runtimeConfig, VITE_, NEXT_PUBLIC_). Triggers: env var, .env,
  process.env, import.meta.env, API key, connection string.
---

You are handling configuration. Goal: **the app reads config from one typed, validated place, fails fast at boot when something is missing, and no secret ever reaches git or the browser.**

## Core rules

1. **One config module, validated at boot.** `process.env` / `import.meta.env` is read in **exactly one file** (`src/config/env.ts` or the framework's equivalent). Everything else imports the typed object.
2. **Fail fast.** Invalid or missing required variables crash the process at startup with a clear message listing *which* keys are wrong — never `undefined` discovered at the first request.
3. **No defaults for secrets or prod-critical values.** `JWT_SECRET ?? 'dev-secret'` is a vulnerability. Defaults are fine only for harmless dev values (`PORT=3000`, `LOG_LEVEL=info`).
4. **`.env.example` is the documentation.** Every variable the app reads appears there with a placeholder and a one-line comment. Real values never do. `.env*` (except `.env.example`) is in `.gitignore`.
5. **Config ≠ secrets.** Non-sensitive config (URLs, flags, limits) may live in committed per-env files; secrets (keys, passwords, tokens, connection strings with credentials) come only from the environment or a secret manager.

## Typed config module (Zod)

```ts
// src/config/env.ts
import { z } from 'zod'

const schema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.coerce.number().int().positive().default(3000),
  LOG_LEVEL: z.enum(['fatal', 'error', 'warn', 'info', 'debug', 'trace']).default('info'),
  DATABASE_URL: z.string().url(),
  JWT_SECRET: z.string().min(32),
  CORS_ORIGINS: z.string().transform(s => s.split(',').map(o => o.trim()).filter(Boolean)),
  FEATURE_NEW_CHECKOUT: z.enum(['true', 'false']).default('false').transform(v => v === 'true'),
})

const parsed = schema.safeParse(process.env)
if (!parsed.success) {
  const keys = parsed.error.issues.map(i => `${i.path.join('.')}: ${i.message}`).join('\n  ')
  console.error(`Invalid environment configuration:\n  ${keys}`) // names only, never values
  process.exit(1)
}
export const env = Object.freeze(parsed.data)
```

- Booleans and numbers are **coerced explicitly** — env values are always strings (`"false"` is truthy).
- Group derived config (`config.db`, `config.auth`) if the app is large, still built from the one parsed object.
- **Never log the values**, only key names (see `secure-coding` A09).
- NestJS: wrap this in `ConfigModule.forRoot({ validate })` or a provider; Express: import `env` where the app is composed — see the framework skill for wiring.

## Frontend / meta-frameworks: public vs server-only

Anything exposed to the browser is **public by definition** — never put a secret there.

| Framework | Server-only | Exposed to browser |
|-----------|-------------|--------------------|
| Nuxt 4 | `runtimeConfig.apiSecret` ← `NUXT_API_SECRET` | `runtimeConfig.public.apiBase` ← `NUXT_PUBLIC_API_BASE` |
| Vite (Vue/React SPA) | — (no server) | `import.meta.env.VITE_*` only |
| Next.js | `process.env.X` in server code | `NEXT_PUBLIC_*` |

- Nuxt: declare keys in `nuxt.config.ts` `runtimeConfig` with empty defaults and override via `NUXT_*` env at runtime; read with `useRuntimeConfig()`. Don't read `process.env` in app code.
- SPA builds bake `VITE_*` at **build time**; one image per environment, or inject a `config.json` at runtime if one build must serve many envs.
- Third-party keys that must be public (Maps, analytics) are restricted by domain/referrer in the provider console.

## Environments

- `local` (developer `.env`), `test` (`.env.test`, committed if it holds no secrets, deterministic values), `staging`, `production` (injected by the platform/secret manager).
- Never branch business logic on `NODE_ENV === 'production'`; use explicit flags (`FEATURE_X`, `EMAIL_DRIVER=smtp|log`). `NODE_ENV` is for framework optimizations.
- Tests don't depend on the developer's `.env`; they set what they need.

## When a human must act

If a new variable needs a real value someone must obtain (API key, OAuth app, DB credentials, webhook secret), **create a manual task** in `workflow/manual-tasks/NN-slug.md` from `workflow/templates/manual-task.md`: where to get it, the exact variable name, which environments, how to verify. Tell the user. Add the placeholder to `.env.example` in the same change.

## Checklist before finishing

- [ ] New variables are declared in the schema with correct type/coercion and validated at boot.
- [ ] `process.env`/`import.meta.env` is not read outside the config module.
- [ ] `.env.example` updated with placeholder + comment; real `.env` files are git-ignored.
- [ ] No secret has a default, is logged, or is exposed through a public/`VITE_`/`NUXT_PUBLIC_`/`NEXT_PUBLIC_` variable.
- [ ] Manual task created for any value a human must provision.

## Out of scope (hand off)

- General secret-handling, crypto and auth rules → `secure-coding`.
- Passing env into containers, CI secrets, image build args → `docker-ci`.
- DB connection pooling and URL usage → `database-persistence`.
- Framework DI/module wiring of config → `nestjs-backend` / `express-backend`; Nuxt runtime specifics → `nuxt-4-dev`.
