# Backend Tasks

Project: C2 Central Management System  
Role: Senior .NET Backend Architect  
Target stack: .NET 8, ASP.NET Core Web API, Clean Architecture, CQRS + MediatR, FluentValidation, EF Core, PostgreSQL, RabbitMQ, SignalR, xUnit

Inputs:

- `/specs`
- `/ai-rules`
- `/docs/development-sequence.md`
- `/openapi/c2-api.yaml`
- `/database/schema.sql`

## Backend Principles

- Follow Clean Architecture: Domain <- Application <- Infrastructure <- API/Worker.
- Keep controllers thin; controllers validate boundary concerns, call MediatR, return standard envelope.
- Use CQRS commands/queries with MediatR.
- Use FluentValidation for request/command validation.
- Use async/await and cancellation tokens for I/O.
- Use structured logging with trace/correlation/request IDs.
- Enforce JWT/RBAC server-side.
- Write audit logs for workflow transitions, device commands, user actions, retries, failures, and security events.
- Use idempotency keys for command APIs.
- Do not hold DB transactions open during external device calls.
- Do not treat command ACK as physical completion.
- Use optimistic concurrency with `row_version`.

## Proposed Solution Structure

```text
backend/
  C2.sln
  src/
    C2.Api/
    C2.Application/
    C2.Domain/
    C2.Infrastructure/
    C2.Worker/
  tests/
    C2.Domain.Tests/
    C2.Application.Tests/
    C2.Api.Tests/
    C2.Infrastructure.Tests/
    C2.Integration.Tests/
```

## Task List

### BE-001 Solution Setup

**Objective:** Create the .NET 8 solution and project skeleton.

**Scope:**

- Create solution.
- Create API, Application, Domain, Infrastructure, Worker projects.
- Create xUnit test projects.
- Configure nullable reference types and implicit usings.
- Add project references following dependency direction only.

**Input Files:**

- `/ai-rules/RULES.md`
- `/ai-rules/BACKEND-RULES.md`
- `/docs/development-sequence.md`

**Output Files:**

- `/backend/C2.sln`
- `/backend/src/C2.Api/*`
- `/backend/src/C2.Application/*`
- `/backend/src/C2.Domain/*`
- `/backend/src/C2.Infrastructure/*`
- `/backend/src/C2.Worker/*`
- `/backend/tests/*`

**Dependencies:** none

**Validation:** `dotnet build backend/C2.sln`

### BE-002 API Host And Pipeline

**Objective:** Configure ASP.NET Core host, middleware, controllers, OpenAPI, health checks, and dependency registration.

**Scope:**

- Modern `WebApplicationBuilder` host.
- Controllers with `[ApiController]`.
- Centralized exception middleware.
- Correlation middleware for `X-Correlation-Id`, `X-Request-Id`, and `traceId`.
- Standard response envelope.
- Health endpoint.
- HTTPS, authentication, authorization middleware order.
- Feature registration extension methods.

**Input Files:**

- `/specs/07-api-integration.md`
- `/specs/09-security-nfr.md`
- `/openapi/c2-api.yaml`

**Output Files:**

- `/backend/src/C2.Api/Program.cs`
- `/backend/src/C2.Api/Middleware/*`
- `/backend/src/C2.Api/Controllers/HealthController.cs`
- `/backend/src/C2.Application/Common/Envelope/*`
- `/backend/src/C2.Application/Common/Correlation/*`

**Dependencies:** BE-001

**Validation:** `dotnet test backend/C2.sln --filter "Category=ApiBaseline"`

### BE-003 Clean Architecture Layer Contracts

**Objective:** Establish shared abstractions for CQRS, results, validation, time, users, transactions, and domain events.

**Scope:**

- Result pattern.
- Command/query marker interfaces.
- Pipeline behaviors for validation, logging, and transactions.
- Current user abstraction.
- Clock/time provider abstraction.
- Unit of work abstraction.
- Domain event base types.

**Input Files:**

- `/ai-rules/RULES.md`
- `/ai-rules/BACKEND-RULES.md`
- `/ai-rules/CODING-STANDARDS.md`

**Output Files:**

- `/backend/src/C2.Application/Common/*`
- `/backend/src/C2.Domain/Common/*`

**Dependencies:** BE-001

**Validation:** `dotnet test backend/C2.sln --filter "Category=Architecture"`

### BE-004 Domain Entities

**Objective:** Implement core domain entities, enums, value objects, and audit/concurrency fields.

**Scope:**

- `Mrv`, `MrvItem`
- `Workflow`, `WorkflowStep`
- `Device`, `SmartBox`, `SmartBoxCompartment`
- `Amr`, `AmrMission`
- `Robot`, `RobotTask`
- `TelemetryEvent`, `CommandLog`, `Alert`, `AuditLog`
- `OfflineQueueItem`, `ReconciliationRecord`
- enums for workflow, device, mission, task, alert, command states.

**Input Files:**

- `/specs/08-data-model.md`
- `/specs/04-domain-rules.md`
- `/database/schema.sql`

**Output Files:**

- `/backend/src/C2.Domain/Entities/*`
- `/backend/src/C2.Domain/Enums/*`
- `/backend/src/C2.Domain/ValueObjects/*`

**Dependencies:** BE-003

**Validation:** `dotnet test backend/C2.sln --filter "Category=Domain"`

### BE-005 EF Core DbContext

**Objective:** Map the PostgreSQL schema into EF Core with constraints, indexes, row versions, and migrations.

**Scope:**

- `C2DbContext`.
- Entity configurations matching `/database/schema.sql`.
- Unique active workflow per MRV.
- Unique command idempotency by `device_id + idempotency_key`.
- Unique active SMARTBox compartment assignment.
- Active AMR mission and robot task constraints.
- Audit log immutability handled in migration SQL.
- Design-time DbContext factory.

**Input Files:**

- `/database/schema.sql`
- `/specs/08-data-model.md`
- `/specs/07-api-integration.md`

**Output Files:**

- `/backend/src/C2.Infrastructure/Persistence/C2DbContext.cs`
- `/backend/src/C2.Infrastructure/Persistence/Configurations/*`
- `/backend/src/C2.Infrastructure/Persistence/Migrations/*`
- `/backend/src/C2.Infrastructure/Persistence/C2DbContextFactory.cs`

**Dependencies:** BE-004

**Validation:** `dotnet ef migrations list --project backend/src/C2.Infrastructure --startup-project backend/src/C2.Api`

### BE-006 Authentication And RBAC

**Objective:** Implement JWT authentication, refresh tokens, roles, policies, and security audit events.

**Scope:**

- `/api/auth/login`
- `/api/auth/refresh`
- `/api/auth/logout`
- JWT validation.
- Refresh token persistence.
- RBAC policies for Admin, Supervisor, Warehouse Operator, Production User, Maintenance Engineer.
- Security audit for failed login, unauthorized access, token failure, permission violation.

**Input Files:**

- `/specs/07-api-integration.md`
- `/specs/09-security-nfr.md`
- `/ai-rules/SECURITY-RULES.md`
- `/openapi/c2-api.yaml`

**Output Files:**

- `/backend/src/C2.Api/Controllers/AuthController.cs`
- `/backend/src/C2.Api/Auth/*`
- `/backend/src/C2.Application/Auth/*`
- `/backend/src/C2.Infrastructure/Identity/*`

**Dependencies:** BE-002, BE-005, BE-009

**Validation:** `dotnet test backend/C2.sln --filter "Category=Security"`

### BE-007 Workflow State Machine

**Objective:** Centralize valid workflow transitions and reject invalid state changes.

**Scope:**

- Workflow states from specs and OpenAPI.
- Happy path states: received through completed.
- Failure states: failed, retry pending, manual intervention, cancelled, recovery pending, reconciliation required.
- Transition validation service.
- Guard rules for duplicate, offline, emergency, invalid current state.
- Domain tests for valid/invalid transitions.

**Input Files:**

- `/specs/04-domain-rules.md`
- `/specs/05-workflows.md`
- `/openapi/c2-api.yaml`

**Output Files:**

- `/backend/src/C2.Domain/Workflow/*`
- `/backend/src/C2.Application/Workflows/StateMachine/*`
- `/backend/tests/C2.Domain.Tests/Workflow/*`

**Dependencies:** BE-004, BE-005

**Validation:** `dotnet test backend/C2.sln --filter "Category=WorkflowState"`

### BE-008 Audit Logging

**Objective:** Implement immutable audit logging and command logging services.

**Scope:**

- Audit writer interface and implementation.
- Command log writer.
- Audit records for workflow transitions, device commands, user actions, exceptions, retries, security events.
- Correlation and trace ID propagation.
- Audit search query model.
- Prevent update/delete at application layer, backed by DB trigger.

**Input Files:**

- `/specs/04-domain-rules.md`
- `/specs/08-data-model.md`
- `/database/schema.sql`

**Output Files:**

- `/backend/src/C2.Application/Audit/*`
- `/backend/src/C2.Application/Commands/CommandLogging/*`
- `/backend/src/C2.Infrastructure/Audit/*`
- `/backend/src/C2.Api/Controllers/AuditController.cs`

**Dependencies:** BE-005

**Validation:** `dotnet test backend/C2.sln --filter "Category=Audit"`

### BE-009 MRV API

**Objective:** Implement MRV ingestion and retrieval according to OpenAPI.

**Scope:**

- `POST /api/mrvs`
- `GET /api/mrvs/{mrvId}`
- `CreateMrvCommand`, validator, handler.
- Required fields validation.
- Duplicate active workflow protection.
- MRV item mapping.
- Initial workflow creation.
- Audit created for valid and rejected duplicate attempts.
- Standard envelope and error schema.

**Input Files:**

- `/specs/04-domain-rules.md`
- `/specs/07-api-integration.md`
- `/specs/10-acceptance-test.md`
- `/openapi/c2-api.yaml`

**Output Files:**

- `/backend/src/C2.Api/Controllers/MrvsController.cs`
- `/backend/src/C2.Application/Mrvs/Commands/*`
- `/backend/src/C2.Application/Mrvs/Queries/*`
- `/backend/src/C2.Application/Mrvs/Validators/*`
- `/backend/tests/C2.Application.Tests/Mrvs/*`
- `/backend/tests/C2.Api.Tests/Mrvs/*`

**Dependencies:** BE-006, BE-007, BE-008

**Validation:** `dotnet test backend/C2.sln --filter "Category=MRV"`

### BE-010 Workflow APIs

**Objective:** Implement workflow detail, search, and control endpoints.

**Scope:**

- `GET /api/workflows`
- `GET /api/workflows/{workflowId}`
- `POST /api/workflows/{workflowId}/retry`
- `POST /api/workflows/{workflowId}/pause`
- `POST /api/workflows/{workflowId}/resume`
- `POST /api/workflows/{workflowId}/cancel`
- Idempotency header on command APIs.
- RBAC policies for workflow actions.
- Audit for user/system actions.

**Input Files:**

- `/specs/04-domain-rules.md`
- `/specs/05-workflows.md`
- `/specs/07-api-integration.md`
- `/openapi/c2-api.yaml`

**Output Files:**

- `/backend/src/C2.Api/Controllers/WorkflowsController.cs`
- `/backend/src/C2.Application/Workflows/Commands/*`
- `/backend/src/C2.Application/Workflows/Queries/*`
- `/backend/src/C2.Application/Workflows/Validators/*`

**Dependencies:** BE-007, BE-008, BE-009

**Validation:** `dotnet test backend/C2.sln --filter "Category=WorkflowApi"`

### BE-011 Device Registry

**Objective:** Implement device identity, heartbeat, status, and offline detection support.

**Scope:**

- Device registry read/write services.
- Registered device identity and allowed command scope.
- Heartbeat state.
- Last connected timestamp.
- Device offline marking.
- Device query support for SMARTBox, AMR, Robot dashboards.

**Input Files:**

- `/specs/08-data-model.md`
- `/specs/09-security-nfr.md`
- `/database/schema.sql`

**Output Files:**

- `/backend/src/C2.Application/Devices/*`
- `/backend/src/C2.Infrastructure/Devices/*`
- `/backend/src/C2.Api/Controllers/DevicesController.cs`

**Dependencies:** BE-005, BE-008

**Validation:** `dotnet test backend/C2.sln --filter "Category=Devices"`

### BE-012 Integration Adapter Contracts

**Objective:** Define vendor adapter interfaces and canonical integration DTOs.

**Scope:**

- AB3/UM MRV source interface.
- SAP inventory validation interface.
- Kardex picking adapter.
- SMARTBox command/event adapter.
- AMR mission/event adapter.
- Robot packing/event adapter.
- Simulator contracts.
- Health/status contract per adapter.

**Input Files:**

- `/specs/01-input-pack.md`
- `/specs/07-api-integration.md`
- `/docs/development-sequence.md`

**Output Files:**

- `/backend/src/C2.Application/Integrations/Ab3/*`
- `/backend/src/C2.Application/Integrations/Sap/*`
- `/backend/src/C2.Application/Integrations/Kardex/*`
- `/backend/src/C2.Application/Integrations/SmartBoxes/*`
- `/backend/src/C2.Application/Integrations/Amrs/*`
- `/backend/src/C2.Application/Integrations/Robots/*`

**Dependencies:** BE-003, BE-011

**Validation:** `dotnet test backend/C2.sln --filter "Category=AdapterContracts"`

### BE-013 SmartBox Adapter

**Objective:** Implement SMARTBox operations and events through adapter abstraction.

**Scope:**

- `GET /api/smartboxes`
- `GET /api/smartboxes/{smartBoxId}/status`
- `POST /api/smartboxes/{smartBoxId}/doors/{doorId}/open`
- `POST /api/smartboxes/{smartBoxId}/doors/{doorId}/close`
- `POST /api/smartboxes/{smartBoxId}/events`
- Compartment assignment validation.
- Door command validation.
- Open/close command logging.
- Heartbeat, door, battery, fault, emergency, boot events.
- Event deduplication.
- Physical completion only after door event.

**Input Files:**

- `/specs/04-domain-rules.md`
- `/specs/05-workflows.md`
- `/specs/07-api-integration.md`
- `/openapi/c2-api.yaml`
- `/database/schema.sql`

**Output Files:**

- `/backend/src/C2.Api/Controllers/SmartBoxesController.cs`
- `/backend/src/C2.Application/SmartBoxes/*`
- `/backend/src/C2.Infrastructure/Integrations/SmartBoxes/*`
- `/backend/tests/C2.Application.Tests/SmartBoxes/*`
- `/backend/tests/C2.Integration.Tests/SmartBoxes/*`

**Dependencies:** BE-010, BE-011, BE-012, BE-014

**Validation:** `dotnet test backend/C2.sln --filter "Category=SmartBox"`

### BE-014 Messaging And Idempotency Infrastructure

**Objective:** Implement RabbitMQ messaging abstractions, idempotency, retry metadata, and DLQ handling contracts.

**Scope:**

- Message publisher/consumer abstractions.
- Command messages for device operations.
- Event messages for workflow/device/alert updates.
- Idempotency service using command log.
- Retry metadata.
- Dead-letter queue contract.
- Worker DI registration.

**Input Files:**

- `/specs/05-workflows.md`
- `/specs/07-api-integration.md`
- `/database/schema.sql`

**Output Files:**

- `/backend/src/C2.Application/Messaging/*`
- `/backend/src/C2.Infrastructure/Messaging/*`
- `/backend/src/C2.Worker/Messaging/*`

**Dependencies:** BE-008, BE-012

**Validation:** `dotnet test backend/C2.sln --filter "Category=Messaging"`

### BE-015 AMR Adapter

**Objective:** Implement AMR mission dispatch, telemetry ingestion, mission completion, failure, and return-home flow.

**Scope:**

- `GET /api/amrs`
- `POST /api/amrs/{amrId}/missions`
- `POST /api/amrs/{amrId}/events`
- Mission validation: online, battery, no fault, queue availability.
- Mission deduplication by workflow, smartbox, mission type.
- Mission status event handling.
- Battery/GPS/safety/fault telemetry.
- Return-home command trigger.

**Input Files:**

- `/specs/04-domain-rules.md`
- `/specs/05-workflows.md`
- `/specs/07-api-integration.md`
- `/openapi/c2-api.yaml`
- `/database/schema.sql`

**Output Files:**

- `/backend/src/C2.Api/Controllers/AmrsController.cs`
- `/backend/src/C2.Application/Amrs/*`
- `/backend/src/C2.Infrastructure/Integrations/Amrs/*`
- `/backend/tests/C2.Application.Tests/Amrs/*`
- `/backend/tests/C2.Integration.Tests/Amrs/*`

**Dependencies:** BE-010, BE-011, BE-012, BE-014, BE-013

**Validation:** `dotnet test backend/C2.sln --filter "Category=AMR"`

### BE-016 Robot Adapter

**Objective:** Implement robot packing task dispatch and robot event ingestion.

**Scope:**

- `GET /api/robots`
- `POST /api/robots/{robotId}/packing-tasks`
- `POST /api/robots/{robotId}/events`
- Robot handling constraints: single label, max 25x25x5 cm, max 1-2 kg.
- Packing started/completed/failed events.
- Robot health/fault/emergency events.
- Task idempotency and active task protection.

**Input Files:**

- `/specs/04-domain-rules.md`
- `/specs/05-workflows.md`
- `/specs/07-api-integration.md`
- `/openapi/c2-api.yaml`

**Output Files:**

- `/backend/src/C2.Api/Controllers/RobotsController.cs`
- `/backend/src/C2.Application/Robots/*`
- `/backend/src/C2.Infrastructure/Integrations/Robots/*`
- `/backend/tests/C2.Application.Tests/Robots/*`

**Dependencies:** BE-010, BE-011, BE-012, BE-014

**Validation:** `dotnet test backend/C2.sln --filter "Category=Robot"`

### BE-017 SAP And Kardex Adapters

**Objective:** Implement inventory validation and picking integration slice.

**Scope:**

- SAP inventory validation adapter.
- Kardex picking request adapter.
- Picking status handling.
- Timeout and retry behavior.
- Audit validation and picking outcomes.

**Input Files:**

- `/specs/04-domain-rules.md`
- `/specs/05-workflows.md`
- `/specs/07-api-integration.md`

**Output Files:**

- `/backend/src/C2.Application/Integrations/Sap/*`
- `/backend/src/C2.Application/Integrations/Kardex/*`
- `/backend/src/C2.Infrastructure/Integrations/Sap/*`
- `/backend/src/C2.Infrastructure/Integrations/Kardex/*`

**Dependencies:** BE-009, BE-012, BE-014

**Validation:** `dotnet test backend/C2.sln --filter "Category=KardexSap"`

### BE-018 Retry Worker

**Objective:** Implement retry, offline queue replay, reconciliation, escalation, and DLQ worker behavior.

**Scope:**

- BackgroundService for retry queue.
- Exponential backoff: immediate, 5 sec, 15 sec, 30 sec.
- Non-retryable error classification.
- Dead-letter handling.
- Offline queue replay only after safe reconciliation.
- Reconciliation records.
- Alert creation after retry limit.
- Audit every retry/recovery/escalation.

**Input Files:**

- `/specs/05-workflows.md`
- `/specs/07-api-integration.md`
- `/specs/08-data-model.md`
- `/database/schema.sql`

**Output Files:**

- `/backend/src/C2.Worker/Recovery/*`
- `/backend/src/C2.Application/Recovery/*`
- `/backend/src/C2.Infrastructure/Recovery/*`
- `/backend/src/C2.Application/Alerts/*`

**Dependencies:** BE-014, BE-013, BE-015, BE-016

**Validation:** `dotnet test backend/C2.sln --filter "Category=Recovery"`

### BE-019 SignalR/WebSocket Integration

**Objective:** Implement realtime backend event publishing for dashboard, workflow detail, and device telemetry.

**Scope:**

- SignalR hubs:
  - `/ws/operations`
  - `/ws/workflows/{workflowId}`
  - `/ws/devices/{deviceId}/telemetry`
- Authenticated hub connections.
- Group subscription model.
- Event publisher service.
- Publish only after state persistence and audit write.
- Events: workflow, retry, reconciliation, device status, SMARTBox, AMR, robot, alert, delivery, audit.

**Input Files:**

- `/specs/06-ux-behavior.md`
- `/specs/07-api-integration.md`
- `/openapi/websocket-events.md`

**Output Files:**

- `/backend/src/C2.Api/Hubs/*`
- `/backend/src/C2.Application/Realtime/*`
- `/backend/src/C2.Infrastructure/Realtime/*`
- `/backend/tests/C2.Api.Tests/Realtime/*`

**Dependencies:** BE-006, BE-008, BE-010, BE-018

**Validation:** `dotnet test backend/C2.sln --filter "Category=Realtime"`

### BE-020 Alert And Audit APIs

**Objective:** Expose operational alert and immutable audit visibility.

**Scope:**

- `GET /api/audit`
- `GET /api/audit/{auditId}`
- alert query service for dashboard.
- alert acknowledgement command if included in MVP API.
- RBAC protection for audit access.
- Search by workflow, MRV, device, user, timestamp, correlation.

**Input Files:**

- `/specs/04-domain-rules.md`
- `/specs/07-api-integration.md`
- `/database/schema.sql`
- `/openapi/c2-api.yaml`

**Output Files:**

- `/backend/src/C2.Api/Controllers/AuditController.cs`
- `/backend/src/C2.Application/Audit/Queries/*`
- `/backend/src/C2.Application/Alerts/*`

**Dependencies:** BE-006, BE-008, BE-018

**Validation:** `dotnet test backend/C2.sln --filter "Category=AuditApi"`

### BE-021 Unit Tests

**Objective:** Build deterministic xUnit coverage for critical business rules and handlers.

**Scope:**

- Domain state transition tests.
- MRV validators.
- Workflow command/query handlers.
- SMARTBox command and event handlers.
- AMR command and event handlers.
- Robot handlers.
- Retry worker policies.
- Audit writer trigger points.
- Authorization-sensitive behavior.
- Concurrency conflict behavior.

**Input Files:**

- `/ai-rules/TESTING-RULES.md`
- `/specs/04-domain-rules.md`
- `/specs/10-acceptance-test.md`

**Output Files:**

- `/backend/tests/C2.Domain.Tests/*`
- `/backend/tests/C2.Application.Tests/*`
- `/backend/tests/C2.Infrastructure.Tests/*`
- `/backend/tests/C2.Api.Tests/*`

**Dependencies:** BE-004 through BE-020

**Validation:** `dotnet test backend/C2.sln --filter "Category!=Integration"`

### BE-022 Integration Tests

**Objective:** Validate API contracts, persistence behavior, auth/RBAC, messaging, and recovery.

**Scope:**

- WebApplicationFactory-based API tests.
- Standard response envelope and error schema.
- Auth required and forbidden checks.
- EF migration/constraint tests.
- Idempotency tests.
- RabbitMQ abstraction mocked or test container when available.
- Simulator adapter tests.
- Retry/DLQ behavior.
- SignalR event publishing tests.

**Input Files:**

- `/openapi/c2-api.yaml`
- `/database/schema.sql`
- `/ai-rules/TESTING-RULES.md`

**Output Files:**

- `/backend/tests/C2.Integration.Tests/*`

**Dependencies:** BE-005 through BE-020

**Validation:** `dotnet test backend/C2.sln --filter "Category=Integration"`

## Implementation Order

1. BE-001 Solution Setup
2. BE-002 API Host And Pipeline
3. BE-003 Clean Architecture Layer Contracts
4. BE-004 Domain Entities
5. BE-005 EF Core DbContext
6. BE-008 Audit Logging
7. BE-006 Authentication And RBAC
8. BE-007 Workflow State Machine
9. BE-009 MRV API
10. BE-010 Workflow APIs
11. BE-011 Device Registry
12. BE-012 Integration Adapter Contracts
13. BE-014 Messaging And Idempotency Infrastructure
14. BE-017 SAP And Kardex Adapters
15. BE-016 Robot Adapter
16. BE-013 SmartBox Adapter
17. BE-015 AMR Adapter
18. BE-018 Retry Worker
19. BE-019 SignalR/WebSocket Integration
20. BE-020 Alert And Audit APIs
21. BE-021 Unit Tests
22. BE-022 Integration Tests

## Backend Done Criteria

- `dotnet build backend/C2.sln` passes.
- All critical command/query handlers have validators.
- All API responses use standard envelope.
- All command APIs require `Idempotency-Key`.
- All operations carry correlation/request/trace IDs.
- RBAC is enforced on protected endpoints and hubs.
- Workflow transitions are validated by centralized state machine.
- Device commands are logged before dispatch.
- External integrations are behind adapter interfaces.
- Retry behavior is bounded and audited.
- Audit logs are immutable.
- SignalR emits only after persisted state and audit write.
- Unit and integration tests pass or blockers are documented.

