# AGENT.md

AI engineering contract for the C2 Central Management System.

## 1. Project Overview

C2 is a warehouse automation orchestration platform for MRV workflow, Kardex, Mobile Manipulator, SMARTBox, OTSAW AMR/FMCS, realtime monitoring, delivery, recovery, and audit traceability.

Stack:

- Backend: .NET 8 Web API
- Frontend: React TypeScript + Vite
- Architecture: Clean Architecture + CQRS + MediatR
- Database: PostgreSQL
- Realtime: SignalR/WebSocket
- Auth: JWT + RBAC
- Logging: Serilog + CloudWatch
- Monitoring: OpenTelemetry
- Messaging: RabbitMQ optional, required when durable async retry is implemented
- Deployment: AWS ECS Fargate
- CI/CD: AWS CodePipeline + CodeBuild
- Tests: xUnit + React Testing Library

MVP priority: stable workflow execution, integration reliability, realtime visibility, auditability, retry/recovery.

## 2. Architecture Principles

- C2 owns workflow state, task sequence, command history, audit trail, and recovery status.
- Devices own physical state: door, battery, mission, telemetry, fault, emergency stop.
- Use event-driven orchestration for telemetry, workflow updates, alerts, and recovery.
- Commands request action; events confirm actual state.
- Persist workflow state and audit before downstream command dispatch.
- Use adapters for AB3/UM, SAP, Kardex, Mobile Manipulator, SMARTBox, AMR/FMCS.
- Prefer MVP-first modularity; avoid premature microservices.
- Every service exposes logs, metrics, traces, health, and integration status.

## 3. Backend Rules

- Use .NET 8, ASP.NET Core Web API, controllers, DI, async/await.
- Layers: API -> Application -> Domain; Infrastructure depends inward.
- Controllers are thin: authorize, bind, call MediatR, return envelope.
- Business logic lives in Domain/Application.
- Use CQRS with MediatR handlers.
- Use FluentValidation for commands/requests.
- Use Result pattern for application outcomes.
- Use EF Core for PostgreSQL persistence.
- Use optimistic concurrency on workflow/device-operation entities.
- Use cancellation tokens for I/O.
- No static mutable state.

## 4. Frontend Rules

- Use React TypeScript strict mode, Vite, React Query.
- Use feature-based structure.
- No business logic in components.
- API access goes through typed clients and hooks.
- Protect routes and actions by RBAC in UI; backend remains authoritative.
- Handle loading, error, empty, success, stale, offline, and reconnect states.
- Realtime dashboard is MVP priority.
- Critical actions require confirmation.
- Show workflow state, blocking reason, assigned device, retry count, escalation status.

## 5. Security Rules

- JWT required for users.
- RBAC mandatory: Admin, Supervisor, Warehouse Operator, Production User, Maintenance Engineer.
- HTTPS/WSS/TLS only outside local development.
- System/device integrations use API keys for MVP; mTLS/client credentials for production where supported.
- Every device has registered identity and allowed command scope.
- Enforce least privilege server-side.
- Log failed login, unauthorized access, permission violation, token failure, suspicious operation.
- No secrets in source, frontend bundle, logs, database plaintext, or committed config.
- Do not expose stack traces or sensitive implementation details to clients.

## 6. API Rules

- REST/JSON for command/control.
- SignalR/WebSocket for realtime status/events.
- Use resource routes: `/api/mrvs`, `/api/workflows`, `/api/devices`, `/api/smartboxes`, `/api/amrs`, `/api/robots`, `/api/audit`.
- Use standard envelope:

```json
{ "success": true, "data": {}, "message": "OK", "traceId": "uuid", "error": null }
```

- Use standard error:

```json
{ "success": false, "data": null, "message": "Operation failed", "traceId": "uuid", "error": { "code": "CODE", "details": "message" } }
```

- Every request carries `X-Correlation-Id` and `X-Request-Id`.
- Command APIs require `Idempotency-Key`.
- Use ISO 8601 UTC timestamps.
- Validate payloads, route params, query params, WebSocket messages, and device events.

## 7. Database Rules

- PostgreSQL is source for C2 workflow state and audit history.
- Core tables: MRV, MRV item, Workflow, WorkflowStep, Device, SMARTBox, Compartment, AMRMission, RobotTask, TelemetryEvent, CommandLog, Alert, User, AuditLog, OfflineQueue, ReconciliationRecord.
- Use FKs for core relationships; do not cascade-delete operational history.
- Apply audit fields to mutable transactional tables.
- Use `row_version` for optimistic concurrency.
- Enforce:
  - one active workflow per MRV
  - one active assignment per SMARTBox compartment
  - unique `deviceId + idempotencyKey`
  - event dedupe by device, event type, timestamp, sequence number where available
- Store raw vendor payloads for troubleshooting and replay.
- Audit logs are immutable and append-only.

## 8. Workflow Engine Rules

- Workflow starts only after MRV received, validated, and inventory confirmed.
- Enforce centralized state machine.
- Reject invalid transitions.
- One active workflow per MRV.
- Delivery completes only after user collection confirmation, GI label scan, and compartment closure confirmation.
- Human override allowed for robot fault, timeout, delivery failure, safety event.
- Do not progress workflow when required subsystem is offline.
- Physical safety state wins over C2 assumptions.

## 9. Retry & Recovery Rules

- Retry only transient failures: timeout, network failure, 5xx, temporary offline, no acknowledgement.
- Do not retry invalid payload, unauthorized request, invalid config, unsupported command, invalid state, permission denied.
- Default retry: immediate, 5 sec, 15 sec, 30 sec.
- Retries require idempotency key, retry limit, backoff, audit log.
- After retry limit, escalate to operator and move to exception/manual intervention state.
- Preserve workflow state during retry/recovery.
- On reconnect: query device, compare state, reconcile, audit, then resume only if safe.
- Unsafe queued commands must not auto-replay.

## 10. SmartBox Integration Rules

- Commands: open door, close door, query status.
- Events: heartbeat, door opened, door closed, battery alert, fault, emergency stop, boot.
- Door command requires valid door ID, SMARTBox online, no emergency stop, authorized role, valid workflow state.
- Command ACK is not completion; wait for door event.
- Compartment must exist, be unoccupied, operational, and not faulted before assignment.
- Low/critical battery prevents new unsafe missions and raises alert.
- Missing heartbeat marks SMARTBox offline.
- Emergency stop freezes commands and requires operator acknowledgement.

## 11. AMR Integration Rules

- AMR mission dispatch requires AMR online, sufficient battery, no active fault, mission queue availability.
- Mission dedupe: workflowId + smartBoxId + missionType.
- Track mission status, battery, GPS/location, autonomous mode, safety alerts, fault status.
- Delivery completion triggers return-home workflow.
- Mission failure triggers retry, alternate AMR if available, escalation if retry exceeded.
- Offline AMR pauses active delivery and preserves last known location.

## 12. Audit Logging Rules

- Audit every workflow transition, device command, user action, retry, exception, recovery, security event, configuration change.
- Audit record includes timestamp, actor, actor role/type, entity, action, previous/new state, correlation ID, source IP where applicable.
- Device commands log request payload, response payload, result, retry count.
- Failed actions must be audited.
- Audit must be searchable by workflowId, MRV ID, deviceId, userId, timestamp range, correlationId.
- Audit retention minimum: 7 years.
- Standard users cannot update/delete audit records.

## 13. Realtime Rules

- Use SignalR over WSS.
- Channels: operations, workflow, device telemetry.
- Publish workflow/device/alert/audit events only after persistence and audit.
- Events carry eventId, eventType, traceId, correlationId, occurredAt, workflowId/deviceId when applicable.
- Deduplicate by eventId or deviceId + eventType + timestamp + sequenceNo.
- Frontend must show stale/offline state on disconnect.
- On reconnect, resubscribe and refresh active workflow/device views.

## 14. Testing Rules

- Backend: xUnit.
- Frontend: React Testing Library.
- Required backend tests: domain rules, validators, handlers, auth/RBAC, API envelope, errors, concurrency, audit triggers.
- Required frontend tests: user-visible behavior, validation, loading/error/empty/success, RBAC visibility, route protection, API failure.
- Integration tests cover auth, RBAC, validation, standard envelope, idempotency, retry/failure, migrations.
- Messaging tests cover idempotency, retry, DLQ, duplicate handling, failure logging.
- Tests must be deterministic.
- Mock external APIs, RabbitMQ, Redis, AWS, time providers in unit tests.

## 15. DevOps Rules

- Deploy containers to AWS ECS Fargate.
- Use AWS CodePipeline + CodeBuild for CI/CD.
- Build stages: restore, lint, build, test, package, container scan, deploy.
- Use CloudWatch for logs and alarms.
- Use OpenTelemetry for traces/metrics.
- Use Serilog structured JSON logs.
- Add health checks for API, DB, RabbitMQ, integrations.
- Use environment separation and least-privilege IAM.
- Store secrets in approved secret store, not repo or image.
- Release requires smoke checklist, rollback plan, deployment checklist, environment matrix.

## 16. AI Coding Constraints

- AI is advisory only for operations.
- AI must not directly control robots, SMARTBox doors, AMR missions, emergency recovery, or safety workflows.
- Human approval required before operational action, workflow override, device command, recovery decision.
- Keep AI out of MVP critical path.
- Do not train on production telemetry, user data, audit logs, or incidents without governance approval.
- AI recommendations must include reason, confidence, data used, next step.

## 17. Forbidden Patterns

- Business logic in controllers or React components.
- Direct vendor calls from Domain, Application workflow logic, or frontend.
- Frontend-only authorization.
- Fire-and-forget device commands without command log, correlation ID, result tracking, audit.
- Long DB transaction during device call.
- Blind retry without idempotency, limit, backoff, audit.
- State update without state machine validation.
- Treating command ACK as physical completion.
- Continuing workflow when required subsystem is offline.
- Raw secrets in code, logs, DB plaintext, or config.
- Silent failure.
- Manual DB fix as normal workflow recovery.
- Fake production logic or unmarked mock behavior.

## 18. Coding Style

- Prefer clarity over cleverness.
- Keep changes small and reviewable.
- Follow existing project style.
- Use meaningful domain names.
- Avoid unnecessary abstractions.
- Avoid duplicate business logic.
- Use guard clauses.
- Use nullable reference types correctly.
- Use constants/enums/value objects instead of magic strings.
- Use comments only for non-obvious logic.
- Never swallow exceptions.
- Never leak sensitive details.

## 19. Folder Structure

```text
backend/
  src/C2.Api
  src/C2.Application
  src/C2.Domain
  src/C2.Infrastructure
  src/C2.Worker
  tests/C2.*.Tests
frontend/
  src/app
  src/api
  src/features
  src/realtime
  src/routes
  src/types
infra/
database/
openapi/
docs/
tasks/
release/
```

## 20. Delivery Workflow

1. Read relevant `/specs`, `/ai-rules`, `/docs`, `/openapi`, `/database`, `/tasks`.
2. Identify vertical slice and dependencies.
3. Implement Domain/Application first.
4. Add Infrastructure adapters/persistence.
5. Add API/UI boundary.
6. Add validation, RBAC, audit, logging.
7. Add tests.
8. Run validation commands.
9. Update docs/tasks only when behavior or contract changes.
10. Report files changed, tests run, assumptions, risks.

## 21. PR Review Rules

Review for:

- architecture respected
- dependency direction correct
- controllers/components thin
- validation present
- RBAC enforced
- audit preserved
- retry/idempotency safe
- no secrets
- no sensitive logs
- no invalid state transitions
- no direct vendor coupling
- tests cover critical paths
- API contract not broken
- migrations safe and reversible where possible

## 22. Definition of Done

- Builds successfully.
- Tests pass or documented blocker exists.
- Acceptance criteria met.
- Validation added.
- RBAC enforced.
- Audit/logging impact checked.
- Retry/recovery safe where applicable.
- Correlation/idempotency included where applicable.
- No secrets or sensitive logs.
- No broken public contracts.
- Monitoring/health impact considered.
- Documentation updated if contract, workflow, schema, or deployment changed.

## 23. AI Agent Execution Rules

- Prefer existing specs, docs, tasks, OpenAPI, schema, and local patterns.
- Use local skills when relevant:
  - backend-development
  - frontend-development
  - testing-generation
  - api-review
  - clean-architecture-review
  - security-review
  - performance-review
  - devops-review
  - release-management
  - root-cause-analysis
- Do not change architecture without explicit approval.
- Do not invent vendor behavior; use adapter interfaces/simulators until real contract exists.
- Ask only when blocked by missing business/security decision.
- Make minimal safe changes.
- Preserve user changes.
- Prefer implementation over proposal when task is actionable.

## 24. Vertical Slice Development Rules

Each slice must include:

- domain rule/state change
- command/query
- validator
- handler
- persistence mapping
- API endpoint or UI surface
- RBAC policy
- audit/logging
- retry/idempotency if command/integration
- realtime event if operational state changes
- unit tests
- integration/UI tests where relevant

Preferred MVP slice order:

1. MRV create workflow
2. Workflow detail
3. Audit search
4. Device registry and heartbeat
5. SMARTBox assign/open/close
6. Robot packing
7. AMR mission
8. Retry/recovery
9. Realtime dashboard
10. End-to-end MRV-to-collection
11. Failure paths

