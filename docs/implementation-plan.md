# Implementation Plan

Project: C2 Central Management System  
Date: 2026-05-28  
Audience: Senior TPM, AI engineering agents, delivery leads  
Mode: MVP/POC first, production-hardened where safety/reliability requires it

## 1. Delivery Goal

Deliver an MVP/POC that validates end-to-end MRV-to-collection orchestration across AB3/UM, SAP, Kardex, Mobile Manipulator, SMARTBox, AMR/FMCS, and the C2 web dashboard.

MVP must prove:

- MRV ingestion and duplicate prevention
- workflow state orchestration
- vendor adapter pattern
- device command/event separation
- SMARTBox compartment operations
- AMR delivery workflow
- realtime dashboard updates
- JWT/RBAC
- immutable audit logging
- retry, recovery, offline handling, and escalation

## 2. Fixed Stack

| Area | Decision |
| --- | --- |
| Backend | .NET 8, ASP.NET Core, Clean Architecture, CQRS, MediatR, FluentValidation |
| Frontend | React, TypeScript strict mode, Vite, React Query |
| Database | PostgreSQL, EF Core |
| Messaging | RabbitMQ |
| Realtime | SignalR over WSS |
| Deployment | AWS ECS Fargate |
| Auth | JWT, refresh tokens, RBAC; API key for MVP system APIs; mTLS/client credentials later |
| Logging | Structured logs, correlation IDs, command logs, immutable audit logs |
| Monitoring | CloudWatch baseline, OpenTelemetry-ready metrics/traces |

## 3. AI-Agent Rules

Use these local skills by task:

| Task | Skill |
| --- | --- |
| Backend feature | `/skills/backend-development` |
| Frontend feature | `/skills/frontend-development` |
| Tests | `/skills/testing-generation` |
| API review | `/skills/api-review` |
| Architecture review | `/skills/clean-architecture-review` |
| Security review | `/skills/security-review` |
| Performance review | `/skills/performance-review` |
| DevOps review | `/skills/devops-review` |
| Release prep | `/skills/release-management` |
| Production incident | `/skills/root-cause-analysis` |

Agent must always follow:

- read relevant `/specs` and `/ai-rules` before implementation
- keep controllers thin
- keep business logic out of UI
- validate all inputs
- enforce RBAC server-side
- write audit records for critical actions
- include traceId/correlationId/requestId/workflowId where applicable
- make retryable operations idempotent
- do not call vendor APIs from domain logic
- do not send device commands inside long DB transactions
- do not treat command acknowledgement as physical completion
- do not add AI autonomous control to MVP

## 4. Delivery Phases

| Phase | Name | Outcome |
| --- | --- | --- |
| 0 | Foundation | Repo builds, architecture skeleton, local dev stack, CI baseline |
| 1 | Core Domain | Workflow state machine, data model, audit, auth/RBAC |
| 2 | MRV + Workflow | MRV ingestion, validation, workflow creation, duplicate protection |
| 3 | Integration Adapters | SAP, Kardex, Robot, SMARTBox, AMR adapter contracts and simulators |
| 4 | Async + Recovery | RabbitMQ commands/events, retries, offline queue, reconciliation |
| 5 | Realtime UX | SignalR streams and operational dashboard |
| 6 | End-to-End MVP | Full MRV-to-collection workflow across adapters |
| 7 | Hardening | SIT/UAT, performance, security, DevOps, release readiness |

## 5. Milestones

| Milestone | Exit Criteria |
| --- | --- |
| M0 Architecture Ready | `architecture-decisions.md` accepted; solution skeleton created |
| M1 Platform Baseline | API, DB, auth, logging, health checks, CI build pass |
| M2 Workflow Core | state machine, workflow persistence, audit, concurrency tests pass |
| M3 MRV Ingestion | valid MRV creates workflow; invalid/duplicate MRV rejected and audited |
| M4 Adapter Contracts | all vendor adapters have interfaces, DTOs, fake/simulator implementations |
| M5 Command Pipeline | commands persisted, queued, retried, dead-lettered, audited |
| M6 Realtime Dashboard | dashboard shows workflows, devices, alerts, retry/offline state live |
| M7 E2E Happy Path | MRV -> inventory -> Kardex -> robot -> SMARTBox -> AMR -> collection completes |
| M8 Failure Path Ready | robot/SMARTBox/AMR/network failure paths trigger retry, recovery, escalation |
| M9 SIT/UAT Ready | critical acceptance tests pass; smoke checklist and release plan complete |

## 6. Module Breakdown

### Backend Modules

| Module | Scope | Key Outputs |
| --- | --- | --- |
| API Shell | ASP.NET Core host, response envelope, exception middleware, health checks | `/api`, `/health`, standard errors |
| Auth/RBAC | JWT, refresh token, roles, policies, route protection | Admin, Supervisor, Operator, Production, Maintenance roles |
| Domain Core | entities, value objects, workflow states, state transition rules | MRV, Workflow, Device, CommandLog, AuditLog |
| Persistence | EF Core, PostgreSQL migrations, rowVersion, unique constraints | schema, repositories/unit of work |
| Audit | immutable audit writer, security audit, command audit | searchable audit records |
| MRV | `POST /api/mrvs`, payload validation, duplicate protection | workflow created from AB3/UM payload |
| Workflow | commands/queries for lifecycle, pause/resume/retry/cancel | state machine and workflow detail |
| Device Registry | device identity, status, heartbeat, allowed scopes | devices, online/offline states |
| SMARTBox | compartment assignment, open/close/status, events | compartment state and door command flow |
| AMR | mission dispatch, mission status, return-home | AMR mission lifecycle |
| Robot | packing task dispatch, completion/fault events | robot task lifecycle |
| Kardex/SAP | inventory/picking adapter contracts | inventory validation and picking events |
| Messaging | RabbitMQ publishers/consumers, retry, DLQ | durable async command/event pipeline |
| Realtime | SignalR hubs, event publishing | operations/workflow/device/alert streams |
| Monitoring | logs, metrics, traces, health, integration status | CloudWatch/OpenTelemetry-ready telemetry |

### Frontend Modules

| Module | Scope | Key Outputs |
| --- | --- | --- |
| App Shell | routing, layout, auth state, RBAC guards | protected operational portal |
| API Client | typed clients, response envelope handling, auth headers | reusable API layer |
| Realtime Client | SignalR connection, reconnect, subscriptions | live updates |
| Dashboard | active workflows, device status, alerts, retry queue | command-center view |
| Workflow Detail | MRV data, timeline, assigned devices, retry/audit history | operational drilldown |
| SMARTBox View | battery, door state, occupancy, faults, offline state | SMARTBox monitoring |
| AMR View | mission state, battery, location, safety alerts, queue | AMR monitoring |
| Collection View | assigned compartment, authenticate, collect, scan/confirm | production collection flow |
| Alerts | severity, acknowledgement, escalation owner | actionable fault visibility |
| Admin | users, roles, device registry, integration config | MVP admin controls |

### Infrastructure Modules

| Module | Scope | Key Outputs |
| --- | --- | --- |
| Local Dev | docker compose for PostgreSQL/RabbitMQ/backend/frontend | reproducible local run |
| Containers | backend/frontend/worker Dockerfiles | deployable images |
| AWS ECS | task definitions, services, ALB, security groups | Fargate deployment baseline |
| Secrets | environment config, secret references | no secrets in repo |
| CI/CD | build, test, lint, container scan, deploy gates | repeatable delivery |
| Observability | CloudWatch logs/metrics/alarms | operational visibility |

## 7. Implementation Order

Follow this order unless a dependency is explicitly stubbed.

1. Create solution structure: API, Application, Domain, Infrastructure, Worker, tests.
2. Add standard response envelope, exception middleware, correlation middleware, health checks.
3. Add PostgreSQL + EF Core baseline and migrations.
4. Implement Auth/RBAC foundation.
5. Implement core entities and workflow state machine.
6. Implement audit logging and command logging.
7. Implement MRV ingestion and duplicate workflow protection.
8. Implement workflow command/query handlers.
9. Add device registry and heartbeat/offline status.
10. Add RabbitMQ abstraction, publishers, consumers, retry, DLQ.
11. Implement vendor adapter interfaces and simulators.
12. Implement SAP/Kardex workflow slice.
13. Implement Robot packing workflow slice.
14. Implement SMARTBox compartment and door workflow slice.
15. Implement AMR mission workflow slice.
16. Implement recovery, reconciliation, offline queue, and escalation.
17. Add SignalR hubs and backend event publishing.
18. Build frontend app shell, auth, RBAC routes, typed API client.
19. Build dashboard, workflow detail, device views, alerts, collection flow.
20. Run SIT happy path, then failure paths, then performance/security reviews.
21. Prepare release notes, smoke checklist, rollback plan, and deployment checklist.

## 8. Dependency Map

| Item | Depends On | Blocks |
| --- | --- | --- |
| Auth/RBAC | API shell, DB | protected APIs, frontend route guards |
| Audit | DB, correlation middleware | workflow, commands, security events |
| Workflow state machine | domain core | MRV, device workflows, recovery |
| MRV ingestion | workflow, audit, validation | E2E workflow |
| Device registry | DB, auth, audit | SMARTBox, AMR, robot, heartbeat |
| Messaging | RabbitMQ config, command log | retry, async adapters, DLQ |
| Adapter simulators | adapter contracts | SIT without vendor sandboxes |
| SignalR | auth, workflow events | realtime dashboard |
| Frontend API client | API contracts | all UI features |
| Dashboard | API client, SignalR | UAT visibility |
| Recovery | workflow, messaging, device state | failure-path acceptance |
| ECS deployment | containers, config, health checks | release readiness |

## 9. Acceptance Scope By Feature

| Feature | Minimum Acceptance |
| --- | --- |
| MRV | valid payload creates workflow; invalid/duplicate payload rejected; audit created |
| Workflow | valid transitions only; one active workflow per MRV; optimistic concurrency tested |
| Kardex/SAP | request sent through adapter; timeout/retry handled; status updates workflow |
| Robot | packing task dispatched; completion/fault event processed; failure escalates |
| SMARTBox | compartment assigned; door open/close commands audited; telemetry updates state |
| AMR | mission assigned; mission status processed; delivery complete triggers return-home |
| Collection | user authenticates; compartment opens; collection confirmed; workflow completes |
| Dashboard | live workflow/device/alert updates; no manual refresh; offline state visible |
| Retry/Recovery | retry attempts logged; max retry escalates; reconnect reconciles state |
| Audit | immutable record with timestamp, actor/system, entity, action, correlation ID |
| Security | JWT required; RBAC enforced; unauthorized/forbidden requests rejected |

## 10. Definition Of Done

### Feature DoD

- specs/rules reviewed for the feature
- command/query/validator/handler implemented where backend work is needed
- API uses standard response envelope
- input validation implemented
- RBAC enforced server-side
- audit/logging impact handled
- correlation/idempotency included for commands
- retry behavior safe for external operations
- no business logic in controller or UI component
- loading/error/empty/success states handled in UI
- tests added for happy path and critical failure path
- build/test pass locally or failure is documented

### Phase DoD

- milestone exit criteria met
- critical tests pass
- API contracts documented or discoverable
- no critical/high security finding open
- no critical workflow blocker open
- monitoring/logging in place for new services
- release notes updated for completed scope

### MVP DoD

- AC-001 through AC-009 pass
- SIT critical scenarios pass
- UAT workflow, dashboard, collection, recovery, and audit visibility accepted
- API response target below 2 seconds for normal operations
- realtime update target below 1 second for critical dashboard events
- retry/recovery validated for robot, SMARTBox, AMR, and network failures
- deployment checklist, rollback plan, and smoke checklist complete

## 11. Risks And Mitigations

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Vendor APIs unstable/incomplete | workflow delays | adapter contracts, simulators, contract tests, feature flags |
| Hardware retrofit delay | SMARTBox integration blocked | simulator first, hardware abstraction, early field test slot |
| Network/5G instability | stale telemetry, failed commands | heartbeat, offline states, retry queue, reconciliation |
| Workflow race condition | duplicate commands or bad state | state machine, optimistic concurrency, idempotency keys |
| Retry flooding | device overload | exponential backoff, max retry, DLQ, alerting |
| Weak auth/device identity | unsafe operations | JWT/RBAC, device registry, scoped API keys, future mTLS |
| Audit gaps | traceability failure | audit-first command/state transition pattern |
| Timeline compression | reduced UAT quality | vertical slices, simulators, critical path first |
| Telemetry volume | DB/dashboard performance issues | indexes, pagination, retention, later telemetry archival |
| Deployment/network unknowns | release delay | early ECS baseline, network/firewall discovery, environment checklist |

## 12. Review Gates

| Gate | When | Required Skill |
| --- | --- | --- |
| Architecture Gate | after foundation and before E2E | `/skills/clean-architecture-review` |
| API Gate | after each API slice | `/skills/api-review` |
| Security Gate | after auth, device commands, release candidate | `/skills/security-review` |
| Test Gate | every feature and phase exit | `/skills/testing-generation` |
| Performance Gate | before SIT/UAT | `/skills/performance-review` |
| DevOps Gate | before deployment | `/skills/devops-review` |
| Release Gate | before MVP handoff | `/skills/release-management` |

## 13. Agent Task Template

Use this compact prompt shape for implementation tasks:

```text
Act as [role].
Read:
- /specs/[specific files]
- /ai-rules
- /skills/[relevant skill]
- /docs/architecture-decisions.md
- /docs/implementation-plan.md

Implement [module/slice].
Scope:
- [endpoint/component/worker]
- [domain rules]
- [tests]

Constraints:
- Clean Architecture
- CQRS + MediatR
- FluentValidation
- JWT/RBAC
- audit + correlation ID
- idempotent/retry-safe if external command
- no business logic in controller/UI

Output:
- files changed
- tests run
- risks/assumptions
```

## 14. Recommended Vertical Slices

Build in thin, testable slices:

1. MRV create workflow.
2. Workflow detail query.
3. Audit search by workflow ID.
4. Device registry and heartbeat.
5. SMARTBox assign/open/close with simulator.
6. Robot packing task with simulator.
7. AMR mission with simulator.
8. Retry command pipeline.
9. Realtime dashboard stream.
10. End-to-end happy path.
11. Failure path: SMARTBox offline.
12. Failure path: AMR mission failure.
13. Failure path: robot packing failure.
14. Collection and workflow completion.

## 15. Non-Goals For MVP

- AI-driven workflow decisions
- predictive maintenance
- advanced analytics
- multi-site orchestration
- enterprise SSO unless required by stakeholder decision
- mobile native app
- full HA/DR architecture beyond MVP baseline

