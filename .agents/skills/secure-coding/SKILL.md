---
name: secure-coding
description: Use when WRITING, changing, or hardening code that touches a security-relevant surface — auth/sessions/tokens, passwords/crypto, any DB/OS/template/deserialization sink, file paths, outbound requests from user input, uploads, CORS/headers, secrets/config — so the code is built secure by default and verified against OWASP Top 10 (2021) and common weaknesses (CWE Top 25). This is the framework- and language-agnostic PREVENTION+VERIFICATION concern: it produces and fixes code, with a pre-commit self-check. Triggers on "secure this", "make it safe", "harden", "auth/login", "validate input", "sanitize", "escape", "parameterize", "prevent injection/XSS/SSRF", "secure defaults". NOT a read-only audit report — for a Node/Express/Nest REVIEW that only reports findings, use `security-audit-node`. NOT the response envelope/non-leaking error body — that is `api-responses` (reference it, don't re-author). It wires secure behavior into whatever framework skill is active (Express/Nest/Vue/React/Nuxt); it does not replace their mechanics.
---

You are writing or hardening **security-relevant code**. Your job is to make it secure *as you build it* and to **verify** it before you hand it back — not to produce an audit report. You write and fix code. This skill is **language- and framework-agnostic**; the concrete syntax comes from whatever framework skill is active.

## Core principles (apply to every change)

1. **Never trust input.** Treat all of `body`/`query`/`params`/headers/cookies/path/filenames/uploaded content/outbound-target URLs/webhook payloads as hostile. Validate against an **allow-list** (type, shape, length, range, enum, format) at the boundary — reject, don't try to clean. Validation ≠ the output-safety of step 2.
2. **Separate code from data at every sink.** Parameterize queries, pass args as arrays (not shell strings), escape/encode at the point of output for the exact context (HTML, attribute, JS, URL, SQL, shell, LDAP). Never build an interpreted string by concatenating input.
3. **Secure by default, fail closed.** Deny access unless explicitly granted; default config is the locked-down one; an error path must not fall open (e.g. an exception in an auth check = denied, not allowed).
4. **Least privilege & least exposure.** Minimum DB/OS/token scope; return only the fields the caller needs; log the event, never the secret.
5. **Defense in depth.** One control failing should not be game over (validation *and* parameterization *and* least privilege).
6. **Don't invent crypto or auth.** Use vetted libraries and standard algorithms; never hand-roll hashing, token formats, or comparisons.

## Where this skill stops (delegate, don't duplicate)

- **Read-only security review of existing Node/Express/Nest code → `security-audit-node`.** That skill *reports* (severity/file:line/evidence), writes nothing. This skill *builds and fixes*. If asked to "audit and report, don't change anything," hand off to it.
- **Response envelope & non-leaking error bodies → `api-responses`.** When the fix is "stop leaking a stack trace / internal error," make the handler not leak and reference `api-responses` for the body shape; don't re-specify the envelope here.
- **Framework mechanics → the active framework skill** (express-backend, nestjs-backend, vue/react-atomic-design, nuxt-4-dev). You decide *what* security control is needed; that skill decides *how* to wire it (middleware order, guards, pipes, directives).

## Build-secure checklist — OWASP Top 10 (2021) + common CWEs

For each item: the weakness, what to **do**, and the **anti-pattern** to never ship.

### A01 Broken Access Control (CWE-862/863/639)
- **Authenticate then authorize.** Every protected route checks *both* identity and that this identity may act on *this* resource (ownership/tenant/role). Derive the acting user from the verified token/session — **never** from a client-supplied `userId`/`role`/`isAdmin`.
- Stop IDOR: `resource.ownerId === currentUser.id` (or a scoped query `where ownerId = :me`) before read/update/delete.
- Block mass assignment: bind an explicit allow-list of fields; never `save(req.body)` / `Object.assign(entity, req.body)`.
- CORS: an explicit origin allow-list; never `origin:"*"` together with `credentials:true`.

### A02 Cryptographic Failures (CWE-327/328/916/330)
- Passwords: `bcrypt`/`argon2`/`scrypt` with per-user salt — never MD5/SHA-1/plain SHA.
- Randomness for tokens/IDs/IVs: a CSPRNG (`crypto.randomBytes`, `randomUUID`) — never `Math.random()`.
- Symmetric crypto: authenticated mode (AES-GCM) with a random per-message IV; no ECB, no static/hardcoded IV or key.
- TLS verification stays ON (never `rejectUnauthorized:false` / `NODE_TLS_REJECT_UNAUTHORIZED=0`). Encrypt sensitive data in transit and at rest where required.

### A03 Injection (CWE-89/78/79/90/94/611/22)
- **SQL/NoSQL:** parameterized queries / bound query-builder params only. Never string-concat or template-interpolate input into a query; reject object operators where a scalar is expected (`{$gt:""}`).
- **OS command:** `execFile`/`spawn` with an args array; never `exec("… "+input)`. Prefer a library call over shelling out.
- **XSS:** context-correct output encoding; let the template auto-escape. Never `innerHTML`/`dangerouslySetInnerHTML`/`v-html` with unsanitized input — sanitize with a vetted sanitizer if raw HTML is truly required, and lock it behind a CSP.
- **Code/template/deserialization:** no `eval`/`new Function`/`vm` on input; no deserializing untrusted data into live objects; disable XXE (external entities off) in XML parsers.
- **Path traversal:** resolve then confirm the result stays inside the intended base dir; allow-list filenames; never join user input straight into a path.

### A04 Insecure Design (CWE-799/770/840)
- Rate-limit and add backoff/lockout on auth, password-reset, OTP, and expensive endpoints.
- Enforce business rules server-side (price, quantity, state transitions, ownership) — never trust client-sent state.
- Bound everything: body-size limit, upload-size/type limit, pagination caps, timeouts.

### A05 Security Misconfiguration (CWE-16/732)
- Security headers on by default (HSTS, `X-Content-Type-Options`, a CSP; `helmet` or equivalent).
- No debug/introspection/playground, verbose errors, or default credentials in prod; no dev-only DB flags (auto-migrate/`synchronize`/drop-schema) reaching prod.
- Secrets come from the environment/secret manager — never committed; `.env` is git-ignored; validate required env at boot.

### A06 Vulnerable & Outdated Components (CWE-1035/1104)
- Add a dep only with a reason; pin versions and commit the lockfile. Run the ecosystem audit (`npm/pnpm/yarn audit`) and resolve Critical/High before shipping. No `*`/loose ranges on security-relevant packages.

### A07 Identification & Authentication Failures (CWE-287/384/307/620)
- Verify token signatures with an explicit algorithm allow-list and a real secret/key — never `decode()`-and-trust, never `alg:none`, never a `|| "dev-secret"` fallback.
- Compare passwords with the library's verify (`bcrypt.compare`), and secrets with a constant-time compare — never `===` on a plaintext secret.
- Sessions/cookies: `httpOnly`, `secure`, `SameSite`; rotate on privilege change; expire and invalidate on logout/password change. Reset/verify tokens are CSPRNG-generated, single-use, and short-lived.
- Don't leak account existence via divergent responses/timing on login or reset (wording fix lives in `api-responses`).

### A08 Software & Data Integrity Failures (CWE-502/345/1321)
- Verify webhook signatures (Stripe/GitHub/etc.) before acting on the payload.
- Guard against prototype pollution: don't deep-merge untrusted objects into config/targets; block `__proto__`/`constructor`/`prototype` keys.
- Verify integrity of what you execute/install (pinned deps + lockfile, pinned base images).

### A09 Security Logging & Monitoring Failures (CWE-778/532)
- Log auth successes/failures, access-control denials, and privilege changes — with a correlation id.
- **Never log secrets/tokens/passwords/full PII/card numbers**; redact before logging. Don't `console.log(req.body)` on auth routes.

### A10 Server-Side Request Forgery (CWE-918)
- When a feature fetches a user-supplied URL (import, preview, webhook, avatar): allow-list scheme+host, resolve the DNS and block private/link-local/metadata ranges (`127.0.0.0/8`, `10/8`, `172.16/12`, `192.168/16`, `169.254.169.254`, `::1`), and don't auto-follow redirects to those.

## Verify before you hand it back (pre-commit self-check)

Run this on the code you just wrote or changed. Do not call it done until each is satisfied **for your diff**:

- [ ] Every new/changed input is validated at the boundary (type/shape/length/range/allow-list) and rejected when invalid.
- [ ] Every sink your code reaches (SQL/NoSQL/OS/HTML/URL/template/path/deserialization) separates code from data — parameterized/encoded/allow-listed, no string-built interpreted strings.
- [ ] New routes/handlers enforce authN **and** resource-level authZ (ownership/tenant/role), derived from the verified principal.
- [ ] No secret is hardcoded, logged, serialized to the client, or committed; crypto/randomness/token handling follows A02/A07.
- [ ] Errors fail closed and don't leak internals (stack/DB/paths) — response body per `api-responses`.
- [ ] Security-relevant behavior has a test (a rejected-bad-input case, an unauthorized-access case) where the testing skill applies.
- [ ] New deps are justified, pinned, lockfile updated, audit clean.

State any residual risk or assumption you couldn't resolve in code (e.g. a control that must be enforced at the gateway/infra layer).

## When the request is "just make it work"

Security is not optional scope. If the straightforward implementation is unsafe, implement the safe version and note in one line what you hardened and why. If a secure choice needs a decision only the user can make (e.g. which origins to allow, which roles exist), implement the locked-down default and flag the decision rather than leaving it open.
