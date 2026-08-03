---
name: nestjs-backend
description: Use when writing or modifying backend code in a NestJS project — the framework mechanics: modules, providers, dependency injection, controllers, pipes/guards/interceptors/exception filters, and logging setup. Triggers on NestJS decorators/files (@Module, @Injectable, @Controller, *.module.ts, *.service.ts, main.ts with NestFactory), Nest CLI, or "how do I wire this in Nest". NOT for plain Express/Fastify apps without Nest (use the Express sibling skill). Does NOT decide the layering/dependency direction (clean-architecture skill) or how to model the domain — entities, value objects, aggregates (tactical-DDD skill); it only wires those into Nest. The response body shape/safety is owned by the api-responses skill.
---

You are wiring backend code into **NestJS**. Your job is the **framework mechanics only**: how to structure modules, register providers, inject dependencies, keep controllers thin, and set up logging. You do not decide which layer code belongs to or how to model the domain — you make Nest host those decisions correctly.

## Division of labor (read first)

- **This skill** — Nest wiring: modules, providers, DI tokens, controllers, pipes/guards/interceptors/filters, logger setup.
- **clean-architecture (sister skill)** — which layer a class lives in and which way dependencies point. When it says "the use case must not import the ORM", this skill just registers the ORM adapter as a provider and injects it via a token.
- **tactical-DDD (sister skill)** — the internals of entities/value objects/aggregates. This skill never models domain; it only exposes them through providers.
- **api-responses (existing skill)** — the shape and safety of the response body. Your exception filter decides *status + when to log*; api-responses decides *what the JSON looks like and that it leaks nothing*.
- If the request is "model this concept" or "where should this live", defer. If it's "wire this into Nest / register this provider / add a guard/filter/logger", it's yours.

## What this skill DECIDES (defaults — apply unless told otherwise)

1. **One module per feature.** Each feature is a self-contained `*.module.ts` that declares its own controllers and providers and `exports` only what other modules need.
2. **Providers injected via DI, programmed to interfaces + tokens.** Depend on an interface, bind it to a concrete class with a token (`{ provide: TOKEN, useClass: ... }`). Never `new` a dependency inside a class.
3. **Thin controllers.** Controllers only: read the HTTP request, delegate to one provider (use case/service), return the result. No business logic, no data access, no try/catch-to-response.
4. **One global exception filter.** Registered once; converts thrown errors to HTTP. It defers the body format to the api-responses skill.
5. **nestjs-pino as the logger.** Structured JSON logs with a correlation id. (Native `Logger` is acceptable only for tiny apps — see fallback note.)

## Folder structure (per feature-module)

```
src/
  app.module.ts                 # root module: imports feature modules + global config
  main.ts                       # bootstrap: NestFactory, global pipes/filters, logger
  common/                       # cross-cutting Nest mechanics (not a feature)
    filters/
      all-exceptions.filter.ts
    interceptors/
      logging.interceptor.ts
    middleware/
      correlation-id.middleware.ts
    tokens.ts                   # injection tokens shared across features
  orders/                       # one folder per feature-module
    orders.module.ts
    orders.controller.ts        # thin — HTTP only
    orders.service.ts           # feature provider (or a use case from the app layer)
    dto/
      create-order.dto.ts       # request shape + validation (class-validator)
    orders.tokens.ts            # feature-local injection tokens
```

## Naming conventions

- Files: `*.module.ts`, `*.controller.ts`, `*.service.ts`, `*.dto.ts`, `*.filter.ts`, `*.guard.ts`, `*.interceptor.ts`, `*.pipe.ts`, `*.middleware.ts`.
- Classes match the file in PascalCase: `OrdersModule`, `OrdersController`, `OrdersService`, `AllExceptionsFilter`.
- Injection tokens: `SCREAMING_SNAKE_CASE` string or `Symbol`, suffixed by role — `ORDER_REPOSITORY`, `PAYMENT_GATEWAY`. Keep them next to the interface they bind.

## The framework mechanics (what each piece is for)

- **Module** — the unit of composition. `imports` (other modules), `controllers`, `providers`, `exports`. A provider is only visible outside its module if `exports`ed.
- **Provider** — anything injectable (services, repositories, gateways, factories). Registered in `providers`, resolved by DI.
- **Dependency Injection** — constructor injection is the default. For interface-typed deps, use `@Inject(TOKEN)`.
- **Controller** — routing + HTTP binding only. `@Get`/`@Post`, `@Param`/`@Body`/`@Query`. Delegates immediately.
- **Pipe** — transforms/validates input before the handler runs (e.g. global `ValidationPipe` for DTOs).
- **Guard** — authorization/authentication yes-no before the handler (`canActivate`).
- **Interceptor** — wraps the handler: logging, timing, response shaping hooks. Runs before and after.
- **Exception filter** — catches thrown errors and maps them to an HTTP response.

Execution order per request: middleware → guards → interceptors (pre) → pipes → handler → interceptors (post) → exception filter (on throw).

## Logging: setup + strategic logs

- Use **nestjs-pino**: structured JSON, fast, one logger for app + HTTP request logs.
- Attach a **correlation id** per request (middleware or interceptor) so every log line of a request is traceable. Reuse an incoming `x-request-id`/`x-correlation-id` header if present; otherwise generate one.
- **Log at boundaries**: request received/completed (method, path, status, duration, correlation id), unexpected errors (with stack, server-side only), and significant state changes.
- **Do NOT log**: passwords, tokens, API keys, full auth headers, card/PII, request/response bodies containing secrets. Redact them (pino `redact`).
- Log the real error details **server-side**; the client only gets the safe body from the api-responses skill.

## Short examples

**Feature module**

```ts
// orders/orders.module.ts
import { Module } from '@nestjs/common';
import { OrdersController } from './orders.controller';
import { OrdersService } from './orders.service';
import { ORDER_REPOSITORY } from './orders.tokens';
import { PrismaOrderRepository } from './prisma-order.repository';

@Module({
  controllers: [OrdersController],
  providers: [
    OrdersService,
    { provide: ORDER_REPOSITORY, useClass: PrismaOrderRepository },
  ],
  exports: [OrdersService],
})
export class OrdersModule {}
```

**Provider injected via DI (interface + token)**

```ts
// orders/orders.service.ts
import { Injectable, Inject } from '@nestjs/common';
import { ORDER_REPOSITORY } from './orders.tokens';
import type { OrderRepository } from './order-repository.interface';

@Injectable()
export class OrdersService {
  constructor(
    @Inject(ORDER_REPOSITORY) private readonly orders: OrderRepository,
  ) {}

  create(input: CreateOrderInput) {
    return this.orders.save(input); // domain logic lives in the domain/use case, not here
  }
}
```

**Thin controller**

```ts
// orders/orders.controller.ts
import { Controller, Post, Body } from '@nestjs/common';
import { OrdersService } from './orders.service';
import { CreateOrderDto } from './dto/create-order.dto';

@Controller('orders')
export class OrdersController {
  constructor(private readonly orders: OrdersService) {}

  @Post()
  create(@Body() dto: CreateOrderDto) {
    return this.orders.create(dto); // no business logic, no try/catch here
  }
}
```

**Global exception filter** (status + logging only; body format deferred to api-responses)

```ts
// common/filters/all-exceptions.filter.ts
import { ExceptionFilter, Catch, ArgumentsHost, HttpException, HttpStatus } from '@nestjs/common';
import { Logger } from 'nestjs-pino';

@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  constructor(private readonly logger: Logger) {}

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const res = ctx.getResponse();
    const status =
      exception instanceof HttpException
        ? exception.getStatus()
        : HttpStatus.INTERNAL_SERVER_ERROR;

    if (status >= 500) this.logger.error({ err: exception }, 'unhandled error'); // server-side only

    // Body shape/safety is owned by the api-responses skill.
    res.status(status).json(/* safe envelope from api-responses */);
  }
}
```

**Logger setup (nestjs-pino) + correlation id**

```ts
// app.module.ts
import { Module } from '@nestjs/common';
import { LoggerModule } from 'nestjs-pino';
import { randomUUID } from 'crypto';

@Module({
  imports: [
    LoggerModule.forRoot({
      pinoHttp: {
        genReqId: (req) =>
          req.headers['x-request-id'] ?? req.headers['x-correlation-id'] ?? randomUUID(),
        redact: ['req.headers.authorization', 'req.body.password', '*.token', '*.cardNumber'],
        customProps: (req) => ({ correlationId: req.id }),
      },
    }),
  ],
})
export class AppModule {}
```

```ts
// main.ts
import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { Logger } from 'nestjs-pino';
import { AppModule } from './app.module';
import { AllExceptionsFilter } from './common/filters/all-exceptions.filter';

async function bootstrap() {
  const app = await NestFactory.create(AppModule, { bufferLogs: true });
  app.useLogger(app.get(Logger));
  app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));
  app.useGlobalFilters(app.get(AllExceptionsFilter));
  await app.listen(3000);
}
bootstrap();
```

> Fallback: for a tiny app you may use the native `Logger` from `@nestjs/common` instead of nestjs-pino, but still attach a correlation id and keep the same redaction rules.

## Out of scope (defer to the right skill)

- **Layering / dependency direction** (which layer a class belongs to, inward-only imports) → clean-architecture skill.
- **Domain modeling** (entities, value objects, aggregates, invariants, domain events) → tactical-DDD skill.
- **Response body shape and leak-safety** → api-responses skill.
- **Tests** (Jest, e2e, mocking providers) → testing skill.
- **Commit/PR conventions** → commit-conventions skill.
