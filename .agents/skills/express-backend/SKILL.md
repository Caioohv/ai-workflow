---
name: express-backend
description: Use when writing or structuring backend code on an Express app (Node + Express, `app.use`, `express.Router`, `req/res/next`, error-handling middleware) — wiring routers, ordering middlewares, keeping controllers thin over a business/service layer and repositories, and setting up a pino logger with request-id and request/response logging. Triggers on Express project layout, middleware chains, async route handlers, central error handler, and diagnostic logging. NOT for NestJS (modules/providers/DI → use the NestJS sibling skill), NOT for the layering/dependency rule (→ clean-architecture) or domain modeling (→ tactical-DDD), and NOT for the response body's shape/safety (→ api-responses). You wire the framework; those decide structure, domain, and payload.
---

You are wiring an **Express** application: how routers, middlewares, controllers, the business/service layer, and repositories are connected, plus a diagnostic **logger**. This is the *mechanics of the framework* — not the layer boundaries (that is clean-architecture), not the domain model (that is tactical-DDD), and not the response body (that is api-responses).

## This skill decides for you (defaults — follow them, don't reinvent)

- **pino** is the default logger (fast, structured JSON). Reach for winston only if the project already uses it.
- **One centralized error-handling middleware** (4 args) at the very end of the chain. Controllers never build error responses inline — they `throw` or `next(err)`.
- **An async wrapper** so async controllers forward rejections to the error handler automatically. No `try/catch` in every controller.
- **Thin controllers.** A controller reads the request, calls exactly one business/service function, and hands the result to the response. No business logic, no data access, no query building.
- **Every request carries a correlation id** and is logged on entry and exit.

## Folder structure

```
src/
  app.js                 # builds the express app: middlewares + routers + error handler. Exports app.
  server.js              # imports app, reads PORT/env, listens. The ONLY file that binds a port.
  config/
    env.js               # reads + validates process.env once, exports a typed config object
    logger.js            # pino instance (single shared logger)
  middlewares/
    request-context.js   # assigns/propagates x-request-id (correlation id)
    request-logger.js    # logs request in/out with duration
    error-handler.js     # the 4-arg central error middleware
    async-handler.js     # wrapper: catches async rejections -> next(err)
  routes/
    index.js             # mounts every feature router under its base path
    users.routes.js      # one router per resource/feature
  controllers/
    users.controller.js  # thin: request -> service call -> response
  services/              # business layer (shape/rules owned by clean-architecture + DDD skills)
  repositories/          # data access (owned by the architecture skills)
  errors/
    app-error.js         # base error carrying httpStatus + machine code
```

### File naming

- Routers: `<resource>.routes.js` (`users.routes.js`)
- Controllers: `<resource>.controller.js`
- Services: `<resource>.service.js`
- Repositories: `<resource>.repository.js`
- One resource/feature per file; plural resource name.

## Middleware order (in `app.js` — order is behavior, not style)

1. Security/infra: `helmet()`, `cors()`, body parsers (`express.json()`).
2. `request-context` — assign the correlation id first so everything downstream can log it.
3. `request-logger` — log entry/exit.
4. Feature routers (`app.use('/api', routes)`).
5. 404 fallback (`app.use((req,res,next) => next(new NotFoundError()))`).
6. **Central error handler — always last.**

A 4-arg middleware placed before the routers will NOT catch their errors. It must come last.

## Concrete examples (keep them this short)

**Router** — declares paths, binds handlers, wraps async:

```js
// routes/users.routes.js
import { Router } from 'express';
import { asyncHandler } from '../middlewares/async-handler.js';
import * as users from '../controllers/users.controller.js';

const router = Router();
router.get('/:id', asyncHandler(users.getById));
router.post('/', asyncHandler(users.create));
export default router;
```

**Thin controller** — request in, one service call, response out. No logic, no try/catch:

```js
// controllers/users.controller.js
import * as usersService from '../services/users.service.js';

export async function getById(req, res) {
  const user = await usersService.getById(req.params.id);
  res.status(200).json({ data: user }); // envelope owned by api-responses skill
}
```

**Async wrapper** — forwards rejections to the error handler:

```js
// middlewares/async-handler.js
export const asyncHandler = (fn) => (req, res, next) =>
  Promise.resolve(fn(req, res, next)).catch(next);
```

**Central error handler** — the one place errors become responses (4 args, last in chain):

```js
// middlewares/error-handler.js
export function errorHandler(err, req, res, next) { // eslint-disable-line no-unused-vars
  const status = err.httpStatus ?? 500;
  // log the REAL error server-side, with correlation id
  req.log.error({ err, code: err.code, reqId: req.id }, 'request failed');
  // client-facing body/shape/safety is the api-responses skill's job
  res.status(status).json({
    error: { code: err.code ?? 'INTERNAL_ERROR', message: err.publicMessage ?? 'Something went wrong' },
  });
}
```

**Logger setup (pino)** + **request logging middleware**:

```js
// config/logger.js
import pino from 'pino';
export const logger = pino({
  level: process.env.LOG_LEVEL ?? 'info',
  redact: ['req.headers.authorization', 'req.headers.cookie', '*.password', '*.token'],
});
```

```js
// middlewares/request-context.js
import { randomUUID } from 'node:crypto';
export function requestContext(req, res, next) {
  req.id = req.headers['x-request-id'] ?? randomUUID();
  res.setHeader('x-request-id', req.id);
  next();
}
```

```js
// middlewares/request-logger.js
import { logger } from '../config/logger.js';
export function requestLogger(req, res, next) {
  req.log = logger.child({ reqId: req.id }); // child logger carries the correlation id everywhere
  const start = process.hrtime.bigint();
  req.log.info({ method: req.method, url: req.originalUrl }, 'request received');
  res.on('finish', () => {
    const ms = Number(process.hrtime.bigint() - start) / 1e6;
    req.log.info({ status: res.statusCode, ms: Math.round(ms) }, 'request completed');
  });
  next();
}
```

## Logging strategy

- **Correlation id on every log.** Use a `logger.child({ reqId })` so every downstream log line (service, repo, error) is traceable to one request. Echo it back in the `x-request-id` response header.
- **Log entry and exit** of each request: method + path in; status + duration out.
- **Levels:** `error` = failures/5xx; `warn` = handled anomalies/4xx worth noticing; `info` = request lifecycle + key milestones; `debug` = detailed diagnostics off in production. Drive the threshold from `LOG_LEVEL`.
- **Log the real error server-side** in the central handler (full `err`, code, reqId) — the client gets only the safe body.
- **Never log sensitive data:** passwords, tokens, auth headers, cookies, full card/PII, secrets. Configure pino `redact` paths (shown above) and never `logger.info(req.body)` blindly. Do not leak internals to logs you would not want exported — and never to the client (that safety line is the api-responses skill's).

## Out of scope (defer to the right skill)

- **Layer boundaries / dependency rule** (where code lives, which way imports point) → **clean-architecture** skill. This skill only wires the plumbing between them.
- **Domain modeling** (entities, value objects, aggregates inside `services/`) → **tactical-DDD** skill.
- **NestJS** (modules, providers, DI, decorators) → the **NestJS** sibling skill. Do not apply this skill to a Nest project.
- **Response body shape, error codes, and payload safety** → **api-responses** skill. You place the central error handler; it decides what the body looks like and that it leaks nothing.
- **Testing** (Jest) → the testing skill.
