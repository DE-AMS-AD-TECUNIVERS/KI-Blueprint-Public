# Security checklist

OWASP-aligned, with examples for a FastAPI + Pydantic + MongoDB stack. Severities below are
starting points — adjust by exploitability, blast radius, and hot-path (see SKILL.md §3).

> **Template note:** This file is deliberately generic. A project's own security checklist
> names its auth gates, unauthenticated routes, service identities, secrets, and known weak
> spots, which together map its attack surface. Fill in
> [Project-specific rules](#project-specific-rules) in your **private** repository and keep
> that version out of public ones.

## Project-specific rules

Replace each placeholder with your project's rule and a pointer to the ADR or doc that owns
it. Drop what doesn't apply.

- `<Auth gates: where they live, what each one checks, which one all others build on>`
- `<Public routes: which routes are deliberately unauthenticated, how each is protected>`
- `<Service identities: which non-user credentials exist, the only paths they may reach>`
- `<Object-level authorization: the central mechanism, its rules, documented exceptions>`
- `<Secret-bearing settings that must never be logged or returned>`
- `<Expensive endpoints and their rate limits / payload caps>`
- `<Libraries the project has retired and must not reintroduce>`

## Authorization & object-level access (the highest-value class)

- **Auth gate present.** Every endpoint carries an authentication gate (on the route or on
  its router), except the documented public routes. A new endpoint without one = **MAJOR**.
- **One choke point.** New gates build on the project's base gate, so account-level checks
  (e.g. a deactivated account) apply everywhere. A gate that bypasses it = **MAJOR**.
- **Service credentials stay on service paths.** A credential meant for machine-to-machine
  calls is never accepted on a user-facing endpoint, alone or as a fallback: it skips the
  per-user checks. = **MAJOR**.
- **Object-level authorization (BOLA / IDOR) — beyond "has a dependency."** A role check on
  the route is not enough: every user-triggered mutation verifies that the caller may act
  on **this specific resource**, in the mutating layer, through the project's central
  authorization mechanism rather than an ad-hoc check. A mutation that skips it =
  **MAJOR**. Documented exceptions are not findings.
- **Deny by default.** An empty role, scope, or assignment set grants nothing.
- **Least privilege.** A route that admits more roles than the action needs = **MODERATE**.

## Signed inbound webhooks / callbacks

- A route that an external system calls without a user session verifies a signature (e.g.
  an HMAC over the payload with a shared secret) and compares it in constant time
  (`hmac.compare_digest`, never `==`).
- Weakening, removing, or bypassing that check = **MAJOR**, and so is a new
  unauthenticated route without equivalent verification.

## Injection

- No query or command built by f-string / `%` / `.format` with user input.
- **MongoDB operator injection:** never pass a user-controlled dict straight into a query
  filter — a caller can smuggle `$where`, `$ne`, `$gt`, or a catastrophic `$regex`. Bind
  specific fields explicitly and escape user input that ends up in a regex (`re.escape`).
  = **MAJOR** when user-reachable.
- No `eval` / `exec` / `compile` or shell execution with user input = **MAJOR**.

## Secrets & configuration

- No secrets, API keys, connection strings, or credentials in source.
- Secret-bearing settings use a masking type (e.g. `pydantic.SecretStr`), so they don't
  show up in logs, `repr`, or tracebacks.
- Debug and verbose modes are off in production and never widen error responses; debug
  and test routes aren't reachable there.

## Input validation (at the boundary)

- Validate all external input in the schema / router layer.
- File uploads: type, size (a configured maximum), content.
- URL inputs: scheme allowlist, no SSRF vectors. SSRF-vulnerable URL handling = **MAJOR**.
- Path traversal prevented in every file / storage operation.

## Error-response leakage

- Don't return raw internals (stack traces, queries, internal ids) to callers.
- **Validation-error handlers must not return `exc.errors()` unfiltered** — in Pydantic
  v2, `errors()` echoes the submitted `input` value (and `ctx` / `url`), leaking personal
  data and internal field structure. Serialize a sanitized subset (`type` / `loc` / `msg`).
  = **MODERATE**.
- Error messages don't echo raw user-supplied identifiers or filenames in a way that
  enables enumeration.
- **Every new domain exception is mapped to an HTTP status** in the central handler, or it
  silently becomes a 500. = **MODERATE**.

## Logging & PII

- No personal data, tokens, secrets, or raw exception text containing user input in log
  messages — respect the project's anonymisation rules (`AGENTS.md`).
- Prefer structured fields and a correlation / request ID.

## DoS / resource limits

- List / query endpoints paginate with a **server-enforced** maximum page size.
  - Unbounded `.to_list()` without a limit = **MODERATE**.
  - Attacker-controlled `limit` / `skip` without an upper bound = **MAJOR**.
  - Aggregation over a full collection without a bounding `$match` stage = **MODERATE**.
- Expensive operations (third-party API calls, file processing, exports) are rate-limited
  and payload-capped.

## Mass assignment

- Request models declare explicit fields, no `extra="allow"`. = **MODERATE**.
- Partial updates use `model_dump(exclude_unset=True)`.
- **Output side:** responses go through an explicit response schema / `response_model`, so
  internal document fields and personal data don't leak.

## Dependency & supply-chain (diffs touching `pyproject.toml` / lock files)

- New or bumped dependencies are maintained and free of known CVEs.
- Flag deprecated or unmaintained libraries and unpinned version ranges. Parsers of
  untrusted input (documents, images, archives) and crypto / token libraries deserve the
  closest look: attacker input reaches them directly.
- Don't add a dependency that duplicates a capability already present (see reuse-over-
  reinvention in [clean-code.md](./clean-code.md)).
