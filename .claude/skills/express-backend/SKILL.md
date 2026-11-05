---
name: express-backend
description: >-
  Express app mechanics: routers, middleware order, thin controllers over
  services, async handler, central error middleware, pino logger with request
  id. Triggers: Express, app.use, express.Router, req/res/next, error-handling
  middleware. Not for NestJS.
---

You wire an **Express** app. Layering comes from `clean-architecture`, domain shape from `ddd-tactical`, response bodies from `api-responses`.

## Defaults (follow them)

- **`app.js` builds the app, `server.js` is the only file that listens.** Lets tests import the app without binding a port.
- **One router per resource** (`users.routes.js`), mounted in `routes/index.js`.
- **Thin controllers:** read request → call one service function → send result. No business logic, no data access, no try/catch.
- **Async wrapper** forwards rejections to `next(err)`; controllers just `throw`.
- **One central 4-arg error middleware, last in the chain.** Logs the real error server-side; the body follows `api-responses`.
- **pino** logger (winston only if already in the project) with a child logger per request carrying the correlation id, `redact` for auth headers, cookies, passwords, tokens. Never `logger.info(req.body)`.

## Middleware order (order is behavior)

1. `helmet()`, `cors({ origin: allowList })`, `express.json({ limit: '100kb' })`
2. request context (assign/propagate `x-request-id`)
3. request logger (in: method + url; out: status + duration)
4. routers
5. 404 → `next(new NotFoundError())`
6. error handler — **always last**, or it won't catch router errors

## Layout

```
src/
  app.js  server.js
  config/{env.js, logger.js}
  middlewares/{request-context.js, request-logger.js, async-handler.js, error-handler.js}
  routes/{index.js, users.routes.js}
  controllers/users.controller.js
  services/  repositories/  errors/app-error.js
```

## Example

```js
export const asyncHandler = (fn) => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next)

// routes/users.routes.js
router.get('/:id', asyncHandler(users.getById))

// controllers/users.controller.js
export async function getById(req, res) {
  res.json({ data: await usersService.getById(req.params.id) })   // envelope per api-responses
}

// middlewares/request-context.js + request-logger.js
req.id = req.headers['x-request-id'] ?? randomUUID(); res.setHeader('x-request-id', req.id)
req.log = logger.child({ reqId: req.id })
res.on('finish', () => req.log.info({ status: res.statusCode, ms }, 'request completed'))

// middlewares/error-handler.js
export function errorHandler(err, req, res, _next) {
  const status = err.httpStatus ?? 500
  if (status >= 500) req.log.error({ err }, 'request failed')
  res.status(status).json(/* safe body per api-responses */)
}
```

Log levels: `error` failures/5xx · `warn` notable 4xx · `info` request lifecycle · `debug` off in prod; threshold from `LOG_LEVEL`.

## Checklist

- [ ] Middleware order as above; error handler last.
- [ ] Controllers thin, wrapped by `asyncHandler`, no try/catch.
- [ ] Every log line carries the request id; secrets redacted.
- [ ] Only `server.js` listens.

## Out of scope

- NestJS → `nestjs-backend`; layering → `clean-architecture`; domain → `ddd-tactical`.
- Response body → `api-responses`; endpoint contract → `api-design`.
- Env/config module → `env-config`; persistence → `database-persistence`; tests → `testing-jest`.
