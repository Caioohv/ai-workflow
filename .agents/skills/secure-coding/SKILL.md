---
name: secure-coding
description: >-
  Write, harden or audit security-relevant code (auth, sessions, tokens,
  passwords, crypto, DB/OS/template sinks, file paths, uploads, outbound URLs,
  CORS, secrets) against OWASP Top 10 and CWE. Build mode writes and
  self-checks code; audit mode reports findings without changes.
---

Two modes: **build** (default: write or fix code secure by default, then self-check) and **audit** (report only, when asked to review/audit or by the `security-scan` agent). Framework syntax comes from the active framework skill; response bodies from `api-responses`; config mechanics from `env-config`; secrets in images/CI from `docker-ci`.

## Principles

1. **Never trust input** (body, query, params, headers, cookies, filenames, uploads, URLs, webhooks): validate against an allow-list at the boundary and reject.
2. **Separate code from data at every sink:** parameterize, pass args as arrays, encode for the output context.
3. **Fail closed:** deny unless granted; an exception in a check means denied.
4. **Least privilege and exposure:** minimal scopes, only the fields the caller needs, log events not secrets.
5. **Don't invent crypto or auth:** vetted libraries, standard algorithms.

## Checklist by OWASP 2021 — do ✔ / never ✘ (the ✘ items are what audit mode greps for)

- **A01 Access control:** ✔ authN + resource-level authZ (owner/tenant/role) from the verified principal; scoped queries (`where ownerId = :me`); explicit field allow-list on writes; CORS origin allow-list. ✘ trusting client `userId`/`role`/`isAdmin`; `save(req.body)` / `Object.assign(entity, req.body)`; `origin: '*'` + `credentials: true`; guards defined but not applied, `@Public()` overused.
- **A02 Crypto:** ✔ bcrypt/argon2/scrypt; CSPRNG (`randomBytes`, `randomUUID`); AES-GCM with random IV; TLS verification on. ✘ MD5/SHA-1/plain SHA for passwords; `Math.random()` for tokens; ECB or static IV/key; `rejectUnauthorized: false`, `NODE_TLS_REJECT_UNAUTHORIZED=0`.
- **A03 Injection:** ✔ bound parameters; `execFile`/`spawn` with args array; template auto-escaping; resolve paths and confirm they stay under the base dir. ✘ string-built SQL (`'... ' + id`, `` `${id}` ``, `createQueryBuilder().where('x = ' + v)`, `sequelize.query` interpolation, `$queryRawUnsafe`); Mongo `$where` or `find(req.body)`; `exec('...' + input)`; `eval`/`new Function`/`vm` on input; `innerHTML`/`v-html`/`dangerouslySetInnerHTML` with unsanitized input; XML with external entities on; user input joined into a path.
- **A04 Insecure design:** ✔ rate limit + backoff on auth, reset, OTP and expensive endpoints; business rules (price, quantity, state) enforced server-side; limits on body size, uploads, pagination, timeouts. ✘ `express.json()` without `limit`; unbounded lists.
- **A05 Misconfiguration:** ✔ security headers (helmet: HSTS, nosniff, CSP); required env validated at boot; `.env` git-ignored. ✘ debug/introspection/GraphQL playground in prod; stack traces to clients; `synchronize: true` / drop-schema in prod; default credentials; `trust proxy` wrong behind a load balancer; secrets in Dockerfile/compose.
- **A06 Components:** ✔ justified, pinned deps; lockfile committed; `npm audit` with Critical/High resolved. ✘ `*` or loose ranges on security-relevant packages.
- **A07 Authentication:** ✔ token signature verified with an explicit algorithm allow-list; `bcrypt.compare`; constant-time secret compare; cookies `httpOnly` + `secure` + `SameSite`; rotate on privilege change; invalidate on logout/password change; reset tokens CSPRNG, single-use, short-lived. ✘ `jwt.decode()` and trust; `alg: none`; `|| 'dev-secret'`; `===` on plaintext secrets; responses that reveal whether an account exists.
- **A08 Integrity:** ✔ verify webhook signatures; block `__proto__`/`constructor`/`prototype` keys; pinned deps and images. ✘ deep-merging untrusted objects into config/targets; deserializing untrusted data into live objects.
- **A09 Logging:** ✔ log auth successes/failures, access denials, privilege changes with a correlation id. ✘ logging passwords, tokens, full PII, card numbers; `console.log(req.body)` on auth routes.
- **A10 SSRF:** ✔ for user-supplied URLs: allow-list scheme and host, resolve DNS and block private, link-local and metadata ranges (`127/8`, `10/8`, `172.16/12`, `192.168/16`, `169.254.169.254`, `::1`), no redirects into them. ✘ fetching arbitrary URLs from previews, imports, avatars or webhooks.
- **Data exposure:** ✘ entities serializing `password`/`passwordHash`/tokens (no `@Exclude()`/DTO mapping); secrets in URLs or error bodies.

## Build mode: self-check before handing back

- [ ] New inputs validated at the boundary and rejected when invalid.
- [ ] Every sink reached separates code from data.
- [ ] New routes enforce authN and resource-level authZ from the verified principal.
- [ ] No secret hardcoded, logged, sent to the client or committed.
- [ ] Errors fail closed and don't leak internals (body per `api-responses`).
- [ ] Security behavior has a test (bad input rejected, unauthorized access denied).
- [ ] New deps justified, pinned, audit clean.

If the safe version needs a decision only the user can make (allowed origins, which roles exist), implement the locked-down default and flag it. "Just make it work" never means unsafe: implement the safe version and note in one line what you hardened.

## Audit mode: report, don't edit

1. Map the surface: routes, controllers, `main.ts`, middleware/guards, auth and crypto code, every DB/OS/FS/template/outbound-HTTP sink, config (`.env*`, framework/ORM config, Docker), `package.json` + lockfile.
2. Grep for every ✘ above, then confirm each hit by reading the code around it. Run the ecosystem audit if a lockfile exists.
3. Report only findings with evidence:

```
# Security Audit — <scope> (OWASP Top 10 2021)
Summary: N findings — Critical n, High n, Medium n, Low n, Info n.

| # | Severity | OWASP / CWE | Location | Finding |
|---|----------|-------------|----------|---------|

## [#1] Critical — A03 Injection (CWE-89)
Location: file:line
Evidence: <snippet>
Impact: <one line>
Fix: <what to change, not a diff>; leaking response bodies → `api-responses`
```

Severity: `Critical` (exploitable now: RCE, auth bypass, secret leak) · `High` · `Medium` (needs conditions) · `Low` (hardening) · `Info`. End with a "Clean / not observed" list of the categories checked, plus assumptions you couldn't verify (runtime config, infra controls).
