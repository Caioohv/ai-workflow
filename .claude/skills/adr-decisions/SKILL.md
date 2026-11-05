---
name: adr-decisions
description: >-
  Record significant, hard-to-reverse technical decisions (framework, DB, ORM,
  auth, API style, ID format, deviating from a convention) as ADRs in
  workflow/decisions/, and respect accepted ones when specifying, implementing
  or reviewing. Triggers: decide, trade-off, X or Y, ADR, why did we choose.
---

You are recording or applying a **decision that shapes the codebase**. ADRs keep the *why* next to the code so future agents and humans don't re-litigate settled choices or silently break them.

## Where things go (don't mix them)

| File | Holds | Example |
|------|-------|---------|
| `workflow/definition.md` | **What** the project is and its current stack (the summary) | "Backend: NestJS + Prisma + Postgres" |
| `workflow/decisions/NN-slug.md` | **Why** a significant choice was made, the options weighed, consequences | "Use Prisma over TypeORM because…" |
| `workflow/project-memory.md` | **Gotchas** discovered while working | "Prisma `P2002` needs mapping to 409" |

When an ADR is accepted, update the one-line summary in `definition.md` so they stay consistent.

## When an ADR is required

Write one when the decision is **costly to reverse** or **affects many future tasks**:

- Choice of framework, runtime, database, ORM, queue, cache, hosting, CI provider.
- Cross-cutting patterns: auth/session strategy, error/response envelope, API style (REST/GraphQL/tRPC), versioning, ID format, multi-tenancy, state-management library.
- Deliberately **deviating** from a skill's rule or an existing ADR (the deviation is the decision).
- Adding a dependency that becomes structural (UI kit, validation lib, date lib).

Skip it for local, reversible choices. If in doubt: "Would a new teammate ask *why is it like this?*" → write it.

## File convention

- Path: `workflow/decisions/NN-kebab-slug.md`, zero-padded, auto-incremented from the highest existing number (same convention as tasks).
- Template: `workflow/templates/adr.md`. Keep it **short** — one screen. An ADR is not a design doc.
- Status: `proposed` → `accepted` | `rejected`; later `deprecated` or `superseded by NN`.
- **ADRs are immutable once accepted.** To change a decision, write a new ADR that supersedes it and set the old one's status to `superseded by NN-slug` (the only edit allowed on an accepted ADR).

## How to write one

1. **Context** — the forces: requirements, constraints, what hurts today. Facts, not the answer.
2. **Options considered** — 2–4 real options, each with one-line pros/cons. Include "do nothing" when it's viable.
3. **Decision** — one sentence in active voice: "We will use X for Y."
4. **Consequences** — what becomes easier, what becomes harder, follow-up work, and the **rules future code must follow** (these are what the reviewer checks).

Agents in auto mode (`spec-creator-auto`, `implementer-auto`, `executor-auto`) may write ADRs with status `accepted` when the decision is required to proceed and is consistent with `definition.md`; mark it `proposed` and tell the user when it's a genuine judgment call they should confirm.

## Applying ADRs (implementers, executors, reviewers)

- Before implementing, skim titles in `workflow/decisions/` and read the ones relevant to the task.
- Code must follow the **Consequences** rules of every accepted ADR. If a task conflicts with one, stop and surface it — don't silently deviate.
- Reviewers: a change that violates an accepted ADR without a superseding ADR is a rejection reason.

## Example

```markdown
# 03 — Use cursor pagination for public list endpoints

**Status:** accepted
**Date:** 2026-03-14
**Supersedes:** —

## Context
Order lists grow unbounded; offset pagination gets slow past ~100k rows and duplicates items when new orders arrive between pages.

## Options considered
- **Offset/limit** — simple, supports "jump to page"; slow on large offsets, unstable under inserts.
- **Cursor (keyset)** — stable and fast at any depth; no random page access.

## Decision
We will use opaque cursor pagination (`?cursor=&limit=`) for all public list endpoints.

## Consequences
- Responses include `nextCursor` (null at end); `limit` is capped at 100.
- Admin-only tables may still use offset.
- Every list query must have a deterministic sort ending in the primary key.
```

## Checklist before finishing

- [ ] The decision is significant enough to deserve an ADR (or you skipped it consciously).
- [ ] File is numbered, slugged, and follows `workflow/templates/adr.md`.
- [ ] At least two options with honest trade-offs.
- [ ] Consequences state concrete rules future code must follow.
- [ ] Superseded ADR (if any) has its status updated; `definition.md` summary is consistent.

## Out of scope

- Project-wide definition and stack summary → `workflow/definition.md` (`discover`).
- Gotchas and error fixes → `workflow/project-memory.md`.
- The technical content of the choice itself → the relevant skill (e.g. `database-persistence`, `api-design`, `state-management`).
