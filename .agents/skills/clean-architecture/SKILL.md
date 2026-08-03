---
name: clean-architecture
description: Use when deciding WHERE code lives across layers and which way dependencies point — organizing a codebase into entities / use cases / interface adapters / frameworks, defining use case boundaries (input/output ports), wiring repository/gateway ports and their adapters, or enforcing the Dependency Rule (inward only). Framework- and language-agnostic; based on Robert C. Martin's "Clean Architecture". Triggers: "clean architecture", "layers", "use case", "boundaries / ports & adapters", "dependency rule", "hexagonal", "where should this code go", "separate business logic from framework". NOT for how to model the domain itself (rich entities, value objects, aggregates, domain events → use the tactical-DDD skill), and NOT for the mechanics of any specific framework (Express/Nest/Vue/React) or testing.
---

You are organizing code into **layers** and enforcing the **Dependency Rule**. Your job is the *separation of concerns and the direction of dependencies* — not domain modeling, not framework mechanics.

## Division of labor (read this first)

- **This skill decides WHERE things live and which way dependencies point.** Layers, boundaries, ports, adapters, imports allowed/forbidden.
- **Tactical DDD (sister skill) decides HOW to model the domain** — rich entities, value objects, aggregates, domain events, what a repository *contains*. When a file lives in the `entities` layer, DDD governs its internals; this skill only says it belongs there and may not import outward.
- **Framework skills (Express, Nest, Vue, React) own the outermost layer's mechanics.** This skill says controllers/routers/ORM live in the outer layer and adapt inward; how to register an Express route or a Nest module is theirs.
- If a request is purely "model this domain concept" or "wire this framework feature", defer. If it's "how do I structure this / where does this belong / stop the framework leaking into my logic", it's yours.

## The four layers (inner → outer)

1. **Entities** — enterprise-wide business rules. Pure. Know nothing about the app around them.
2. **Use Cases** — application-specific business rules. Orchestrate entities to fulfill one operation. Declare the *ports* (interfaces) they need.
3. **Interface Adapters** — controllers, presenters, gateway/repository implementations, DTO ↔ model mappers. Convert between the use case's shapes and the outside world's shapes.
4. **Frameworks & Drivers** — web framework, DB driver/ORM, UI, external SDKs, main/composition root. Glue and details.

## The Dependency Rule (the one law)

**Source-code dependencies point only inward.** An inner layer must never name, import, or know about anything in an outer layer.

- Entities import: nothing from your app.
- Use cases import: entities, and *their own ports* (interfaces they declare). Never a controller, ORM, HTTP, or framework type.
- Interface adapters import: use cases, ports, entities. They *implement* the ports.
- Frameworks/drivers import: everything; wire it all together in the composition root.

Data crossing a boundary is a **plain, inner-defined structure** (an input/output model or entity) — never a framework request object, ORM row, or ORM entity.

## Folder structure (default — adapt names, keep the boundaries)

```
src/
  entities/                 # layer 1 — pure business rules
  use-cases/                # layer 2 — one folder or file per use case
    create-order/
      create-order.usecase.ts       # the interactor
      create-order.input.ts         # input boundary (request model)
      create-order.output.ts        # output boundary (response model)
      ports/
        order-repository.ts         # port the use case depends on (interface)
  adapters/                 # layer 3 — implement ports, translate shapes
    controllers/
    presenters/
    gateways/               # *Repository / *Gateway implementations
    mappers/
  infrastructure/           # layer 4 — framework, db, external SDKs
    http/                   # routers/controllers wiring (framework skill's mechanics)
    persistence/            # ORM setup, db client
  main.ts                   # composition root — builds & injects everything
```

The boundary that matters is the layer, not the exact folder name. `adapters/` may be split as `interface-adapters/`; `infrastructure/` may be `frameworks/`. Keep four conceptual rings.

## Naming conventions

- Use case (interactor): `CreateOrderUseCase` / `create-order.usecase.ts`.
- Input boundary: `CreateOrderInput` (a.k.a. request model). Output boundary: `CreateOrderOutput` (response model).
- Port for persistence: `*Repository` **as an interface owned by the use case layer** (e.g. `OrderRepository`). Its implementation in adapters is `*Gateway` or `*RepositoryImpl` (e.g. `SqlOrderGateway`, `PrismaOrderRepository`).
- Port for any other outside service (email, payment, clock): `*Gateway` / `*Provider` interface; concrete impl named after the tech (`StripePaymentGateway`).
- Controller: `*Controller`. Presenter: `*Presenter`.

Note the deliberate split from tactical DDD: DDD also uses the word *Repository*. Here, `*Repository` is a **port (interface) declared inward** so the use case stays ignorant of the DB. DDD decides what the repository's methods mean for the aggregate; this skill decides that the interface lives with the use case and the implementation lives outward.

## Use case contract

Every use case exposes one operation and depends only on abstractions:

- Takes an **input boundary** (plain request model), returns/pushes an **output boundary** (plain response model).
- Receives its ports via constructor injection — never constructs its own DB client, HTTP client, or reads env.
- Contains the application rules; delegates enterprise rules to entities; delegates I/O to ports.

## Short example (neutral TypeScript — illustrative, not a framework)

Entity (layer 1) — pure:

```ts
// entities/order.ts
export class Order {
  constructor(readonly id: string, private items: number, private paid = false) {}
  pay() {
    if (this.items === 0) throw new Error("Cannot pay an empty order");
    this.paid = true;
  }
  isPaid() { return this.paid; }
}
```

Port + use case (layer 2) — depends only on an interface it owns:

```ts
// use-cases/pay-order/ports/order-repository.ts
import { Order } from "../../../entities/order";
export interface OrderRepository {           // PORT — points inward
  findById(id: string): Promise<Order | null>;
  save(order: Order): Promise<void>;
}

// use-cases/pay-order/pay-order.usecase.ts
import { OrderRepository } from "./ports/order-repository";

export interface PayOrderInput  { orderId: string; }        // input boundary
export interface PayOrderOutput { orderId: string; paid: boolean; } // output boundary

export class PayOrderUseCase {
  constructor(private readonly orders: OrderRepository) {}   // injected port
  async execute(input: PayOrderInput): Promise<PayOrderOutput> {
    const order = await this.orders.findById(input.orderId);
    if (!order) throw new Error("Order not found");
    order.pay();                       // enterprise rule lives in the entity
    await this.orders.save(order);
    return { orderId: order.id, paid: order.isPaid() };
  }
}
```

Adapter (layer 3) — implements the port, knows the DB, points inward:

```ts
// adapters/gateways/sql-order-gateway.ts
import { OrderRepository } from "../../use-cases/pay-order/ports/order-repository";
import { Order } from "../../entities/order";

export class SqlOrderGateway implements OrderRepository {
  constructor(private readonly db: DbClient) {}    // db is a framework detail
  async findById(id: string): Promise<Order | null> {
    const row = await this.db.query("SELECT * FROM orders WHERE id = $1", [id]);
    return row ? new Order(row.id, row.items, row.paid) : null;   // map row → entity
  }
  async save(order: Order): Promise<void> {
    await this.db.exec("UPDATE orders SET paid = $2 WHERE id = $1",
      [order.id, order.isPaid()]);
  }
}
```

Composition root (layer 4) — the only place that wires concretes to abstractions:

```ts
// main.ts
const gateway = new SqlOrderGateway(dbClient);
const payOrder = new PayOrderUseCase(gateway);   // inject impl into the port
// the framework controller (Express/Nest skill's job) calls payOrder.execute(...)
```

Notice: the use case never imports `SqlOrderGateway` or `DbClient`. Dependency inversion — the arrow at the boundary points *against* the flow of control.

## What this skill DECIDES for you (defaults)

- Four rings; dependencies point strictly inward; the composition root is the only outward-aware wiring point.
- Entities are pure (no framework, no I/O, no annotations tied to a driver).
- Use cases declare their own ports and receive them by injection; they return plain models, not ORM rows or HTTP objects.
- `*Repository` = port (interface) in the use case layer; its implementation (`*Gateway`/`*RepositoryImpl`) lives in adapters.
- Framework/ORM/HTTP types stay in the outer ring and never cross a boundary inward.
- Cross-boundary data is a plain DTO/model owned by the inner side.

## Forbidden imports (enforce these)

- Entity imports a use case, adapter, framework, or ORM. ❌
- Use case imports a controller, presenter, framework, HTTP, ORM, or a concrete gateway. ❌
- Any inner layer references `req`/`res`, an ORM entity/decorator, or an env/config read. ❌
- A port interface living in the adapters or infrastructure layer instead of with its use case. ❌
- Passing a framework request object or ORM row across a use case boundary. ❌

## Out of scope — delegate to sister skills

- **How to model the domain** (rich entities, value objects, aggregates, invariants, domain events) → tactical-DDD skill.
- **Framework mechanics** (Express routing/middleware, Nest modules/providers, Vue/React components) → the respective backend/frontend skill. This skill only says such code lives in the outer ring and adapts inward.
- **Testing** (Jest, test doubles for ports) → testing skill. (This layering makes ports trivially mockable — that's a benefit, not this skill's instructions.)
- **Commit/PR conventions** → commit skill.

## Quick checklist

- [ ] Every source dependency points inward; nothing inner names anything outer.
- [ ] Entities are pure — no framework, ORM, or I/O.
- [ ] Each use case has an input model, an output model, and injected ports.
- [ ] `*Repository`/`*Gateway` ports are interfaces owned by the use case layer.
- [ ] Concrete adapters implement those ports and live in the outer rings.
- [ ] No framework request objects or ORM rows cross a use case boundary.
- [ ] Wiring of concretes to abstractions happens only in the composition root.
