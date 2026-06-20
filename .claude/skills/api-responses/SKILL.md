---
name: api-responses
description: Use when writing or modifying JavaScript/Node API endpoint responses (Express, Fastify, NestJS, Next.js/Remix route handlers, etc.). Ensures responses are human-friendly and never leak internals — stack traces, DB/ORM errors, file paths, secrets, internal IDs or enums.
---

You are writing or changing **JavaScript/Node API responses**. Make every response **human-friendly** and make sure it **never leaks internal details** to the client. Apply this whenever you touch route handlers, controllers, or error-handling middleware (Express, Fastify, NestJS, Next.js/Remix route handlers, etc.).

## Principles

1. **Consistent shape.** Every response — success or error — follows one predictable envelope so clients can rely on it.
2. **Human-friendly messages.** Error messages are plain language a client could show to a user, not raw exceptions.
3. **Stable error codes.** Pair the human message with a short machine-readable `code` so clients can branch without parsing prose.
4. **Correct HTTP status.** 4xx for client mistakes, 5xx for server faults. Never return 200 with an error body.
5. **Leak nothing internal.** The client never sees the implementation.

## Never expose to the client

- Stack traces or exception class names
- Raw database/ORM errors, SQL, constraint names, or driver messages
- File paths, line numbers, internal module/library names
- Environment details, config values, secrets, tokens, connection strings
- Internal IDs, enum values, or table/column names that aren't part of the public contract
- `Cannot read properties of undefined` and other runtime noise

Log the real details server-side; return a safe, generic message to the client.

## Response shapes

Success:

```js
// 200 OK
{ "data": { /* ... */ } }
```

Error:

```js
// 4xx / 5xx
{
  "error": {
    "code": "ORDER_NOT_FOUND",            // stable, machine-readable
    "message": "We couldn't find that order." // human-friendly, safe to show
  }
}
```

Validation error (field-level, still friendly):

```js
// 422 Unprocessable Entity
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Some fields need your attention.",
    "fields": {
      "email": "Enter a valid email address.",
      "password": "Must be at least 8 characters."
    }
  }
}
```

## Error-handling pattern

- Define an `AppError` (or similar) for **expected** errors that carry a safe `code`, `message`, and `status`. These pass straight through to the client.
- For **unexpected** errors (anything that isn't an `AppError`), log the full error internally and return a generic `500` with `{ code: "INTERNAL_ERROR", message: "Something went wrong on our end. Please try again." }`.
- Centralize this in one place (error middleware / exception filter) so individual handlers never format errors ad-hoc.

Example — Express:

```js
class AppError extends Error {
  constructor(code, message, status = 400) {
    super(message);
    this.code = code;
    this.status = status;
  }
}

// central error middleware — register it last
function errorHandler(err, req, res, next) {
  if (err instanceof AppError) {
    return res.status(err.status).json({
      error: { code: err.code, message: err.message },
    });
  }

  // unexpected: log the truth, hide it from the client
  (req.log?.error ?? console.error).call(req.log ?? console, err);
  return res.status(500).json({
    error: {
      code: "INTERNAL_ERROR",
      message: "Something went wrong on our end. Please try again.",
    },
  });
}
```

Usage in a handler:

```js
if (!order) {
  throw new AppError("ORDER_NOT_FOUND", "We couldn't find that order.", 404);
}
```

## Checklist before shipping an endpoint

- [ ] Success and error responses use the same envelope
- [ ] Every error has a stable `code` and a friendly `message`
- [ ] HTTP status codes are accurate
- [ ] No stack traces, DB errors, paths, or secrets can reach the client (check the 500 path too)
- [ ] Validation failures return field-level, user-readable messages
- [ ] Real error details are logged server-side
- [ ] Behavior is identical in dev and prod — nothing extra leaks when `NODE_ENV !== "production"`

## Anti-patterns

- `res.status(500).send(err.message)` or `res.json(err)` → leaks internals.
- Returning the caught error object directly.
- Re-throwing to the framework's default handler that prints a stack trace as the response body.
- Inconsistent shapes (`{ message }` here, `{ error }` there, bare strings elsewhere).
- Telling the client whether an email exists on login (`user not found` vs `wrong password`) → return one generic credential error.
