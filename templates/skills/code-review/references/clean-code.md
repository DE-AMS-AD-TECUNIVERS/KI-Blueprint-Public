# Clean-code checklist

Severities are starting points — adjust by blast radius and hot-path (SKILL.md §3).
Confirm every finding against a real line before reporting it.

> **Template note:** Names and examples below belong to a fictional example project.
> Replace them with your project's conventions.

Three governing rules for everything below:

- **The repo overrides.** A documented repo standard (`AGENTS.md`, `GLOSSARY.md`, ADRs) always
  wins; where it endorses something a heuristic here would flag, suppress the finding.
- **Smell heuristics are judgement calls.** Where a finding rests on a smell heuristic alone
  (rather than a violated invariant or a concrete bug), label it as a judgement call
  ("possible feature envy"), never assert it as a hard violation.
- **Skip what tooling enforces.** Don't report anything the linter, type checker, or CI
  already catches.

## Naming & consistency

- Casing: modules `snake_case`, classes `PascalCase`, functions/methods `snake_case`,
  constants `UPPER_SNAKE_CASE`, private helpers `_underscore`. Domain names match the
  `GLOSSARY.md` glossary. Violations = **MINOR**.
- **Finder/factory naming consistency:** follow the established Active Record names
  (`find_by_*`, `get_or_raise`, `create_new`, `create_from`). A new finder named off-pattern
  = **MINOR/MODERATE**.
- **Consistency with established patterns (distinct from DRY):** flag code that does the same
  job a *different* way than its siblings or the `AGENTS.md` conventions — e.g. hand-building
  a response dict instead of `Schema.model_validate(doc)`; not using
  `model_dump(exclude_unset=True)` for partial updates; adding a router-level `try/except`
  instead of raising a domain exception and letting the central exception handler translate
  it. Pointless divergence = **MODERATE**; search out the canonical sibling (SKILL.md §1) and
  cite it.

## DRY & duplication

- Check **within-file and across files/domains** — in a repo with many domains, copy-paste
  drift across siblings is the main risk.
- Literal copy-paste of non-trivial logic = a finding at the **2nd** occurrence; mere
  structural similarity = rule of three (extract after the third).
- Risk-weight: duplicated **auth / state-transition / atomic-write** logic = **MAJOR** (drift
  becomes a correctness/security hole); generic duplication = **MODERATE**; test boilerplate
  = **MINOR**.
- Don't over-abstract — premature abstraction is worse than duplication. Extracted shared code
  goes to `app/core/` (or a domain's public API), consistent with the boundary rules in
  [architecture.md](./architecture.md).

## Reuse over reinvention

Before accepting new custom code, check whether something already does the job:

1. **`app/core/`** utilities — e.g. a `utcnow()` helper (don't hand-roll
   `datetime.now(timezone.utc)`), the id service, the per-aggregate lock, the rate limiter,
   blob storage.
2. **The model** — an existing finder/factory/verify method (e.g. the webhook signature
   check, `Order.search()`).
3. **`pyproject.toml` deps + the stdlib** — before hand-rolling or adding a new library.

Severities: reinventing security/crypto/auth primitives (HMAC, JWT, password hashing) =
**MAJOR**; duplicating an existing project utility/finder = **MODERATE**; trivial stdlib
duplication (e.g. `utcnow`) = **MINOR**.

## Dead code

- Unused imports / variables / local assignments = **MINOR**.
- Unreachable code (after `return`/`raise`, always-false branches) = **MODERATE**.
- Orphaned model finders/factories with no callers, branches left over from finished
  refactorings or migrations, and commented-out code = **MODERATE**.
- Before flagging "never called," confirm the symbol is truly unreferenced repo-wide (search
  for usages) — Active Record finders are easy to mistake for dead when called dynamically.

## Overcomplication / KISS

- Pass-through services/wrappers that only forward to a model method (delete the layer) =
  **MODERATE**.
- Speculative generality / single-use abstractions / YAGNI extensibility hooks = **MODERATE**.
- Re-implementing what Beanie / Active Record already provides = **MODERATE**.
- Over-decomposition (a swarm of tiny indirection-only functions) is as much a smell as a
  god-function. Clever one-liners, nested comprehensions, dynamic `getattr/setattr`,
  metaprogramming = **MINOR** unless they obscure correctness.

## Function design (heuristics, not bright lines)

- Single responsibility; very long functions, long parameter lists (consider a dataclass/
  TypedDict), and deep nesting (>~3 levels) are smells to **consider** splitting — weigh
  against readability, not as automatic findings.

## General smells

Smell names follow the classic refactoring catalogue (Martin Fowler, *Refactoring*).

- **Magic numbers / unnamed literals** → named constant (`UPPER_SNAKE_CASE`); duplicated or
  business-threshold literals = **MODERATE**, otherwise **MINOR**.
- **Primitive obsession** → use an `Enum`/value object instead of bare `str`/`UUID` for
  states, roles, and shared ids. = **MODERATE**.
- **Feature envy** → code that works mostly on another object's data belongs on that
  object's model (Active Record). = **MODERATE**.
- **Shotgun surgery** → a single logical change has to touch many places; in this example
  project, a sub-workflow state change must always be accompanied by the parent-status sync —
  flag a missing parallel update. = **MAJOR** for a state-sync miss.
- Data clumps, boolean-flag parameters, long message chains (`a.b.c.d`), god classes =
  **MINOR/MODERATE**.
- **Repeated switches** → the same `if/elif` cascade or `match` on one type shows up in
  several places → one shared mapping or polymorphism instead. = **MODERATE**.
- **Divergent change** → one module keeps changing for unrelated reasons → split it along
  those reasons. = **MODERATE**.
- **Refused bequest** → a subclass uses little of its parent or overrides most of it →
  prefer composition over inheritance. = **MODERATE**.

## Stale comments

- Comments/docstrings that contradict the code — especially any claim that conflicts with the
  "derived status written on mutation, never recomputed at read time" invariant. = **MINOR**
  (**MODERATE** if a misleading docstring on a model method or state transition could cause
  misuse).
- `TODO`/`FIXME` with no issue reference, or describing already-done work; commented-out code.

## Error handling

- Don't swallow exceptions silently (log at minimum). Don't catch bare `Exception` except to
  re-raise or log + return a safe value.
- Domain exceptions inherit the project's base exception (e.g. `AppBaseException`); use
  specific types over generic `ValueError`/`RuntimeError`. Avoid redundant router
  `try/except` — let the central exception handler translate.

## Async patterns

- **No blocking I/O in async** — CPU-bound or synchronous library calls inside an async
  handler (e.g. pandas in a reporting service) must run via `asyncio.to_thread`. Prefer the
  async variants of cloud SDKs and HTTP clients; flag *new* sync/blocking calls. On a hot
  path = **MAJOR**; cold path = **MINOR**.
- No fire-and-forget coroutines without error handling. `asyncio.gather(...)` should isolate
  per-task failures (`return_exceptions=True` or explicit handling).
- Use the per-aggregate lock (or an atomic update such as `find_one_and_update`) for
  concurrency-sensitive read-then-write.

## Type safety

- No `# type: ignore` without an explanatory comment; avoid `Any` and bare `dict` in public
  signatures; type Optional fields explicitly (`X | None`).
