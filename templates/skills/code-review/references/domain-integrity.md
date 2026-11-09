# Domain-model integrity checklist

The example domain is a workflow state machine with denormalized projections — the
highest-value bugs here are **bypassed transitions** and **silent drift**. Reference:
`GLOSSARY.md`, `AGENTS.md`, the ADRs in `docs/adr/`.

> **Template note:** States, entities, and rules below belong to a fictional order/approval
> example. Replace them with your own domain model.

## State machine correctness

- State transitions defined in a single transition table (e.g. `VALID_TRANSITIONS`) are
  enforced by model methods. **No direct state assignment that bypasses the transition
  validator** = **MAJOR**.
- Terminal / decided states behave per the glossary (e.g. a `REJECTED` order may only be
  reactivated by a documented system event, never by a user endpoint).
- Auto-advance and cross-workflow triggers are business logic, not user actions — they
  belong on the model/service, not in routers.

## Beanie conventions

- `class Settings` defines the collection name; indexes declared in `Settings.indexes` (not
  field annotations alone) — missing index for a new query pattern = **MODERATE**.
- `save()` hook updates `updated_at`; factory methods (`create_new`, `create_from`) handle
  uniqueness checks.

## Split sources of truth / drift

The same fact stored in two places that can diverge. Typical cases:

- **A parent status that is a denormalized projection** of its sub-workflow states (e.g.
  `Order.status` derived from its approval steps), written on mutation. **When you mutate
  any sub-workflow state, confirm the parent-status sync runs in the same flow.** A drifted
  projection = **MAJOR** (data integrity).
- State lists, terminal-state definitions, role strings, and derivation rules must be
  defined **once**, not re-hardcoded across modules.
- General check: **for every writer of a source field, verify each one also updates its
  derived/cached copy.**
- **Read/write normalization symmetry:** when a field is normalized on write (e.g. roles
  `.strip().lower()` in the schema validators), every new query or filter over that field
  must apply the **same** normalization to its inputs — otherwise the filter silently misses
  (`?roles=Admin` never matches the stored `admin`). Silent mismatch on a normalized field =
  **MODERATE**.

## Concurrency & data consistency

- Operations that must be atomic use the project's per-aggregate lock (or an atomic update
  such as `find_one_and_update`). A read-then-write sequence on shared state without the
  lock = **MAJOR** (race).
- Concurrent-duplicate creation is handled by catching a dedicated `*AlreadyExistsError`
  (e.g. `OrderAlreadyExistsError`) — new creation paths should do the same.
- Cross-document consistency is maintained via service orchestration, not scattered writes.

## Idempotency & migration / back-compat

- **User-decision endpoints must be idempotent** per the glossary — repeating a decision is
  classified (no-op / applied / partially applied), never duplicated effects. A decision
  handler that doesn't classify replays = **MAJOR**.
- **Model / collection / ID changes must preserve back-compat** with the documents already in
  the database. New fields must default safely for existing documents; a change existing
  documents can't absorb ships a one-off migration script (e.g. `scripts/migrate_*.py`) with
  its pure logic tested. = **MAJOR** for a breaking change to a persisted shape without one.
- When a storage layout has been replaced (documented in an ADR), new code must read only
  the current layout. New code that reads or falls back to the retired layout =
  **MODERATE**; remaining fallbacks are legacy, not a pattern to copy.
