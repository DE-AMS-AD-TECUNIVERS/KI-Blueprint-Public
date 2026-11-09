# Architecture checklist

The architecture is **domain-organized Active Record with Beanie** — *not* hexagonal /
ports-and-adapters. Do not expect or demand repositories, ports, or adapter layers; model
classes own persistence and domain logic directly. Reference: `AGENTS.md` architecture
section, `GLOSSARY.md` glossary.

> **Template note:** Domain names (`order`, `approval`, `audit_log`, …) and rules below
> belong to a fictional example project. Replace them with your own architecture rules.

## Layer responsibilities

**The contract, one line per layer — check every diff against it:**

- **Schemas: only schemas** (request/response shapes + validation, nothing else).
- **Model: the logic of its own domain.**
- **Service: orchestration logic between multiple domains.**
- **Router: HTTP handling.**

| Layer | File | Owns | Must not contain |
|-------|------|------|------------------|
| **Router** | `router.py` | HTTP transport only: parse request, call model/service, wrap already-built content in the response | Business logic, DB queries, direct model mutations, payload/file rendering |
| **Service** | `service.py` | Cross-domain orchestration & side effects (mail, audit log, cascades) | Single-aggregate logic that belongs on a model; HTTP Request/Response objects |
| **Model** | `models.py` | Domain logic, state machines, finders, factories, mutations, lifecycle hooks | Imports from service/router layers |
| **Schemas** | `schemas.py` | Request/response DTOs, validation | Business logic, DB access |

- Router containing business logic = **MAJOR**.
- Model importing service/router-layer code = **MAJOR**.
- Service importing another domain's internals (not its public API) = **MODERATE**.

## Active Record placement (the high-value check here)

- Domain find/create/update/query logic belongs **on the model**, e.g. `Order.create_new()`,
  `Order.search()`, `Document.find_by_order()`, `Approval.get_or_raise()`. Query or mutation
  logic sitting in a `service.py` that should be a model method = **MODERATE** (MAJOR if it
  bypasses a model invariant).
- Services are **mainly for cross-domain side effects** (`AGENTS.md`). A pure single-aggregate
  mutation living in a service is a smell; a service method that only forwards to a model
  method is a pass-through layer to delete.
- Flag **anemic models** — domain logic that has leaked out into routers/services.

## Domain boundaries

- Cross-domain access goes through a domain's public API where practical. If the project
  accepts deep imports (`from app.domains.x.models import ...`) for documented dependencies,
  don't raise false "deep import" findings for them — e.g.:
  - `approval` depends on `order`.
  - The import pipeline orchestrates `order` + `approval` + `audit_log` + `document` — the
    highest-value flow, legitimately cross-domain.
- A domain reaching into an *undocumented* sibling's internals for new coupling = **MODERATE**.

## Project-specific placement rules (these are architectural)

- **Derived status fields are written on mutation, never recomputed at read time** (e.g.
  `Order.status` as a projection of its sub-workflows). Computing it in a read path /
  router / response builder = **MAJOR** (placement + integrity). See `AGENTS.md`.
- **The audit log is append-only and written only via its service** (e.g.
  `audit_log.service.create_event()`). A domain writing audit documents directly =
  **MAJOR** (boundary violation).
- **Generated file / attachment endpoints build the file content in `service.py`**; the
  router parses params and wraps the returned bytes in a `Response`. Point to the canonical
  sibling services and the export conventions ADR. Row/cell building, label maps, encoding,
  or filename choice in a router = **MODERATE**.

## Structure & placement

- Nested / variant layouts are legitimate when documented — do not flag them as
  misstructured (e.g. `order/approval/`, `reporting/dashboard/`, `document/services/`).
- Integration adapters: shared infrastructure lives in `app/core/` (e.g. blob storage, the
  HTTP client); domain-owned messaging lives with its domain. A new shared utility belongs in
  `app/core/`, not duplicated per domain.
- Placement quick-check — "is this code in the right layer?": HTTP parsing/auth deps →
  router; state transitions/domain rules/finders → model; cross-aggregate orchestration →
  service; validation/serialization → schemas; shared utilities → `app/core/`. Misplaced
  code = **MODERATE**.
