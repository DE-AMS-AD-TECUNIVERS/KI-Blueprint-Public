# Test-quality checklist

The example repo is test-heavy, mock-heavy, and fully async: most domains ship
`tests/unit/`. Beanie runs on an async Mongo client; tests lean heavily on
`AsyncMock`/`MagicMock`/`patch`. The biggest risks are **missing tests on the risky paths**
and **tests that pass regardless of correctness**.

> **Template note:** Adapt the risk areas below to your own project.

## Coverage of new logic

- New logic has corresponding tests. Risk-weight the gap:
  - Missing tests for **state-machine transitions / transition-table enforcement /
    cross-domain orchestration** (the highest-risk areas) = up to **MAJOR**.
  - Missing tests for generic new logic = **MODERATE**.

## Tautological / pointless tests (the #1 mock-heavy risk)

- A test that mocks a method and then asserts the mock's own configured return value proves
  nothing. = **MODERATE**.
- A test that re-asserts a production constant ("expected" mirrors the source) = **MODERATE**.
- **Over-mocking that stubs the unit under test** so the test passes even if the real logic is
  broken = **MODERATE**.
- Call-with-no-assertion, or `assert x is not None` as the only check = **MODERATE** (asserts
  nothing meaningful).

## Test design

- Test through **public interfaces**, not private helpers / implementation details. New tests
  exercising `_private` helpers or internal call sequences = **MODERATE** (they break on every
  refactor). Flag new ones; don't churn existing ones.
- **Error-path / negative tests:** cover the raise paths for domain exceptions
  (`get_or_raise`, transition validators, `*AlreadyExistsError`, authorization errors), not
  just the happy path.
- Mock at boundaries (DB, cloud SDKs, external services), not internal collaborators.
- No hardcoded IDs/dates that make tests brittle.

## Async test pitfalls

- A coroutine that is never awaited (e.g. `AsyncMock` misused so the assertion runs against a
  coroutine object) produces a **false pass** — check awaits are real.
- Event-loop / ordering dependence between tests, leaked tasks, or shared mutable mocks across
  tests (`asyncio_mode=auto` makes this easy to get wrong) = **MODERATE**.

## Coverage erosion (review observation, not a tooling change)

- Call out new code paths left untested, and tests that only pass because warnings /
  deprecations are suppressed. Frame as a finding on the change under review; don't prescribe
  CI/coverage configuration here.
