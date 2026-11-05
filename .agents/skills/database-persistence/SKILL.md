---
name: database-persistence
description: >-
  Persistence mechanics in Node/TS: relational schema, constraints and indexes,
  migrations (expand → contract), ORM repository adapters (Prisma, TypeORM,
  Drizzle, Knex), transactions, seeds, pagination queries, N+1. Triggers:
  schema, migration, index, transaction, slow query, repository implementation.
---

You implement the persistence **adapter** for a repository whose interface was already decided (`clean-architecture`, `ddd-tactical`), and keep the database correct and evolvable.

## Rules

**Integrity**
- Every invariant that can be a constraint is one: `NOT NULL`, `UNIQUE`, `FOREIGN KEY`, `CHECK`. App validation is UX; constraints are truth.
- Naming `snake_case`, plural tables, FKs `<entity>_id`; map to camelCase in the ORM.
- `created_at`/`updated_at` as `timestamptz` UTC. Money as integer minor units or `numeric`, never float.
- PK format (UUID v7/ULID vs bigint) is chosen once and recorded via `adr-decisions`.
- Soft delete only with a business reason; then every query filters it and unique indexes become partial (`WHERE deleted_at IS NULL`).
- Index FKs and frequent `WHERE`/`ORDER BY` columns; composite = equality columns first, then range/sort.

**Migrations**
- Schema changes only via migrations committed with the code; never `synchronize: true` / `prisma db push` outside a throwaway DB.
- Read generated migrations: generators turn renames into drop + add.
- Never edit a migration that ran in a shared environment; write a new one.
- Zero-downtime by default: **expand → migrate → contract** (add nullable → dual write → backfill in batches → enforce `NOT NULL` → drop old later). Large-table indexes `CONCURRENTLY` (non-transactional migration).
- Production migrations run in the deploy pipeline (`migrate deploy`), not at app boot. If a DB or credentials must be provisioned, create a manual task.

**Repository adapter**
- ORM types never leave the adapter. A Mapper per aggregate (`toDomain`/`toPersistence`); rehydration doesn't re-fire creation events.
- `save()` persists the whole aggregate in one transaction.
- Optimistic concurrency where edits race: `version` column in the `WHERE`; zero rows → conflict error.
- Translate driver errors (unique violation `P2002`/`ER_DUP_ENTRY`) into domain/application errors at the adapter.

**Queries and transactions**
- No query inside a loop: use `include`/joins or `WHERE id IN (...)`.
- Paginate and cap every list: keyset/cursor for large or live tables, offset only for small admin lists.
- Raw SQL only when needed and always parameterized (`$queryRaw` tagged template, never `$queryRawUnsafe` with input).
- Transactions short, no external I/O inside. The use case owns the unit of work; side effects after commit or via an outbox table.
- One client instance per process; a pooler in serverless.
- Seeds idempotent (`upsert`); reference data required in every env belongs in a migration.

## Example

```ts
export class PrismaOrderRepository implements OrderRepository {
  constructor(private readonly db: PrismaClient) {}

  async findById(id: OrderId) {
    const row = await this.db.order.findUnique({ where: { id: id.value }, include: { items: true } })
    return row ? OrderMapper.toDomain(row) : null
  }

  async save(order: Order) {
    const d = OrderMapper.toPersistence(order)
    await this.db.$transaction([
      this.db.order.upsert({ where: { id: d.id }, create: d.order, update: d.order }),
      this.db.orderItem.deleteMany({ where: { orderId: d.id } }),
      this.db.orderItem.createMany({ data: d.items }),
    ])
  }
}
```

## Checklist

- [ ] New invariants enforced by constraints.
- [ ] Reviewed migration; destructive changes follow expand → contract.
- [ ] FKs and hot filter/sort columns indexed.
- [ ] Mapper in place; no ORM type crosses the adapter.
- [ ] No N+1; lists paginated and capped; transactions short.
- [ ] Driver errors translated.

## Out of scope

- Repository interface and layer placement → `clean-architecture`; aggregate design → `ddd-tactical`.
- Security beyond parameterization → `secure-coding`; connection string handling → `env-config`.
- Repository tests → `testing-jest`.
