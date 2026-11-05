---
name: nestjs-backend
description: >-
  NestJS mechanics: feature modules, providers and DI tokens, thin controllers,
  pipes/guards/interceptors/exception filters, nestjs-pino logging. Triggers:
  @Module, @Injectable, @Controller, *.module.ts, NestFactory, "how do I wire
  this in Nest".
---

You wire code into **NestJS**. Layering comes from `clean-architecture`, domain shape from `ddd-tactical`, response bodies from `api-responses`; you make Nest host those decisions.

## Defaults (apply unless told otherwise)

1. **One module per feature** (`orders/orders.module.ts`) declaring its controllers and providers; `exports` only what other modules need.
2. **Depend on interfaces bound by tokens:** `{ provide: ORDER_REPOSITORY, useClass: PrismaOrderRepository }` + `@Inject(ORDER_REPOSITORY)`. Never `new` a dependency inside a class. Tokens are `SCREAMING_SNAKE_CASE` symbols/strings next to the interface.
3. **Thin controllers:** read params/body, call one provider (use case/service), return. No business logic, no data access, no try/catch-to-response.
4. **Global `ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true })`** with class-validator DTOs in `dto/`.
5. **One global exception filter** decides status and logging; the body follows `api-responses`.
6. **nestjs-pino** logger with a correlation id (`x-request-id` reused or generated) and `redact` for auth headers, passwords, tokens. Native `Logger` only for tiny apps, same rules.
7. Use **guards** for authN/authZ, **interceptors** for cross-cutting timing/mapping, **pipes** for input transform. Order: middleware → guards → interceptors → pipes → handler → interceptors → filter.

## Layout

```
src/
  main.ts                 # NestFactory, global pipe/filter, logger
  app.module.ts           # imports feature modules + LoggerModule/ConfigModule
  common/{filters,interceptors,middleware}/
  orders/{orders.module.ts, orders.controller.ts, orders.service.ts, orders.tokens.ts, dto/}
```

File suffixes: `*.module|controller|service|dto|guard|pipe|filter|interceptor.ts`; classes match in PascalCase.

## Example

```ts
@Module({
  controllers: [OrdersController],
  providers: [PayOrderUseCase, { provide: ORDER_REPOSITORY, useClass: PrismaOrderRepository }],
})
export class OrdersModule {}

@Controller('orders')
export class OrdersController {
  constructor(private readonly payOrder: PayOrderUseCase) {}
  @Post(':id/payment')
  pay(@Param('id') id: string) { return this.payOrder.execute({ orderId: id }) }
}

// app.module.ts
LoggerModule.forRoot({
  pinoHttp: {
    genReqId: (req) => req.headers['x-request-id'] ?? randomUUID(),
    redact: ['req.headers.authorization', 'req.headers.cookie', '*.password', '*.token'],
  },
})

// main.ts
const app = await NestFactory.create(AppModule, { bufferLogs: true })
app.useLogger(app.get(Logger))
app.useGlobalPipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }))
app.useGlobalFilters(app.get(AllExceptionsFilter))   // logs 5xx server-side, body per api-responses
app.enableShutdownHooks()
```

## Checklist

- [ ] Feature lives in its own module; only needed providers exported.
- [ ] Interface dependencies injected via tokens; no `new` inside providers.
- [ ] Controllers are thin and free of try/catch.
- [ ] DTOs validated by the global pipe; unknown fields rejected.
- [ ] One global filter; logs carry correlation id; secrets redacted.

## Out of scope

- Layers and dependency direction → `clean-architecture`; domain modeling → `ddd-tactical`.
- Response body shape and leak-safety → `api-responses`; endpoint contract → `api-design`.
- Config module and env validation → `env-config`; persistence → `database-persistence`.
- Plain Express apps → `express-backend`; tests → `testing-jest`.
