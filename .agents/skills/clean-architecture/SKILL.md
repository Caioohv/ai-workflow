---
name: clean-architecture
description: >-
  Decide where code lives across layers (entities, use cases, adapters,
  frameworks) and enforce the inward-only Dependency Rule with ports & adapters.
  Triggers: clean/hexagonal architecture, layers, use case, ports, where should
  this code go, keep the framework out of business logic.
---

You decide **which layer code lives in and which way dependencies point**. Not domain modeling, not framework mechanics.

## Defaults (apply without asking)

- **Four rings, inner → outer:** `entities` (enterprise rules, pure) → `use-cases` (one operation each, declare their ports) → `adapters` (controllers, presenters, gateway/repository impls, mappers) → `infrastructure` (framework, ORM, SDKs, composition root).
- **Dependencies point only inward.** Inner code never names, imports or knows anything outer.
- **Ports are interfaces owned by the use case** (`OrderRepository`, `PaymentGateway`); implementations live in adapters and are named after the tech (`PrismaOrderRepository`, `StripePaymentGateway`).
- **Use cases** take a plain input model, return a plain output model, and receive ports by constructor injection. They never build clients or read env.
- **Data crossing a boundary is a plain inner-defined structure**, never `req`/`res`, an ORM row or an ORM entity.
- **Only the composition root (`main.ts` / DI module) wires concretes to ports.**

## Layout (rename folders freely, keep the rings)

```
src/
  entities/
  use-cases/pay-order/{pay-order.usecase.ts, pay-order.input.ts, pay-order.output.ts, ports/order-repository.ts}
  adapters/{controllers,presenters,gateways,mappers}/
  infrastructure/{http,persistence}/
  main.ts
```

## Example

```ts
// use-cases/pay-order/ports/order-repository.ts — port, owned inward
export interface OrderRepository {
  findById(id: string): Promise<Order | null>
  save(order: Order): Promise<void>
}

// use-cases/pay-order/pay-order.usecase.ts
export class PayOrderUseCase {
  constructor(private readonly orders: OrderRepository) {}
  async execute({ orderId }: PayOrderInput): Promise<PayOrderOutput> {
    const order = await this.orders.findById(orderId)
    if (!order) throw new OrderNotFoundError(orderId)
    order.pay()                       // enterprise rule stays in the entity
    await this.orders.save(order)
    return { orderId: order.id, paid: order.isPaid() }
  }
}

// main.ts — the only place that knows both sides
const payOrder = new PayOrderUseCase(new PrismaOrderRepository(prisma))
```

## Forbidden

- Entity imports a use case, adapter, framework or ORM.
- Use case imports a controller, presenter, HTTP/framework type, ORM or a concrete gateway.
- Any inner layer touches `req`/`res`, ORM decorators/entities, or reads env/config.
- A port declared in adapters/infrastructure instead of next to its use case.
- A framework request object or ORM row passed across a use case boundary.

## Checklist

- [ ] Every import points inward.
- [ ] Entities are pure (no framework, ORM, I/O).
- [ ] Each use case has input model, output model and injected ports.
- [ ] Ports live with the use case; impls live outward.
- [ ] Wiring happens only in the composition root.

## Out of scope

- How to model entities, value objects, aggregates, events → `ddd-tactical`.
- Framework mechanics → `express-backend` / `nestjs-backend` / Vue/React skills.
- Repository implementation details (schema, migrations, transactions) → `database-persistence`.
- Tests → `testing-jest`.
