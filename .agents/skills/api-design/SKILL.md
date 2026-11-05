---
name: api-design
description: >-
  Design the contract of an HTTP API: resource URLs, methods, status codes,
  pagination/filter/sort params, idempotency, versioning and breaking changes,
  OpenAPI. Triggers: new endpoint, route design, REST, which status code,
  pagination, API versioning, webhook design.
---

You design the **contract** clients depend on: URLs, verbs, codes, parameters, evolution. Body envelope and error wording come from `api-responses`.

## Rules

**URLs**
- Plural nouns, kebab-case, no verbs: `/orders`, `/orders/{orderId}/items`. Nest at most one level; beyond that use a filter (`/items?orderId=`).
- Non-CRUD actions as a sub-resource noun (`POST /orders/{id}/cancellation`). If the project picks another style, record it via `adr-decisions` and stay consistent.
- Public IDs are opaque (UUID/ULID). JSON fields camelCase, dates ISO 8601 UTC, money `{ amount: <minor units>, currency }`.

**Methods and codes**
- `GET` read-only (200) · `POST` create (201 + `Location`) or action (200/202) · `PUT` full replace · `PATCH` partial · `DELETE` (204).
- Precise codes: 400 invalid input · 401 unauthenticated · 403 forbidden · 404 not found, **also for resources the caller can't see** · 409 conflict/duplicate/invalid transition · 429 + `Retry-After` · 503 dependency down. Use 422 only if the project distinguishes it from 400 (decide once).
- Never `200` with `{ success: false }`.

**Collections**
- Every list paginated with capped `limit` (default 20, max 100). Cursor by default (`?cursor=&limit=` → `nextCursor`); offset only for small/admin lists. Shape per `api-responses`.
- Filters are query params named after fields (`?status=paid`, `createdFrom`/`createdTo`); sort `?sort=-createdAt,name` from an allow-list.

**Validation and safety of the contract**
- Explicit request schema per endpoint (Zod, class-validator DTO, JSON Schema) validated at the boundary; unknown fields rejected on writes.
- Prefer one schema as the source for validation, types and OpenAPI (`zod-to-openapi`, `@nestjs/swagger`).
- `POST`s that move money, create orders or send messages accept an `Idempotency-Key` and replay the stored response on retry.
- Racy edits use `ETag`/`If-Match` or a `version` field → 412/409 on mismatch.

**Evolution**
- Additive = non-breaking (new optional fields, new endpoints). Removing/renaming fields, changing types/meaning/codes, making fields required = breaking → new version (`/v1` URL prefix unless an ADR says otherwise), with `Deprecation`/`Sunset` headers on the old one.
- Clients ignore unknown fields (tolerant reader).

**Async and webhooks**
- Long work: `202` + `Location: /jobs/{id}` exposing `status` and result link.
- Outbound webhooks: `resource.action` names, stable event `id`, `occurredAt`, HMAC signature, retries with backoff.

**Docs**
- OpenAPI 3.1 committed and in sync: summary, request schema, every response code, an example.

## Checklist

- [ ] Noun URLs, ≤ 1 nesting level, consistent casing.
- [ ] Correct method semantics and precise status codes.
- [ ] Lists paginated and capped; filter/sort allow-listed.
- [ ] Request validated; unknown fields rejected on writes.
- [ ] Idempotency on unsafe `POST`s that can be retried.
- [ ] Change is additive or versioned; OpenAPI updated; new conventions recorded as ADR.

## Out of scope

- Body envelope, error messages, not leaking internals → `api-responses`.
- Route wiring → `express-backend` / `nestjs-backend` / `nuxt-4-dev`.
- AuthN/AuthZ, rate limiting, SSRF on webhook targets → `secure-coding`.
- Pagination queries → `database-persistence`.
