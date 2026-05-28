# MASTER BACKEND SLICE PROMPT TEMPLATE

```text
Act as a Senior .NET 8 Backend Engineer.

Read FIRST:
- AGENT.md
- /ai-rules
- /specs
- /tasks/backend-tasks.md

Implement ONLY:
[TASK_ID]

Requirements:
- Follow Clean Architecture
- Follow CQRS + MediatR
- Use FluentValidation
- Use EF Core PostgreSQL
- Use structured logging
- Follow API standards
- Follow security rules
- Add tests

Rules:
- Do NOT implement future tasks
- Do NOT modify unrelated modules
- Keep controllers thin
- Use async/await
- Use cancellation tokens
- Use Result pattern where applicable
- Use standard response envelope
- Use correlation/request IDs
- Use optimistic concurrency where required

Deliver:
1. Changed files summary
2. New files created
3. Important implementation notes
4. Validation commands
5. Assumptions/blockers if any

Validation:
- solution builds
- tests pass
- no architecture violations
```

---

# BE-001 PROMPT — Solution Setup

```text
Implement ONLY:
BE-001 Solution Setup

Scope:
- Create .NET 8 solution
- Create:
  - C2.Api
  - C2.Application
  - C2.Domain
  - C2.Infrastructure
  - C2.Worker
- Create xUnit test projects
- Configure nullable reference types
- Configure implicit usings
- Add proper project references
- Follow Clean Architecture dependency direction

Validation:
dotnet build backend/C2.sln
```

---

# BE-002 PROMPT — API Host And Pipeline

```text
Implement ONLY:
BE-002 API Host And Pipeline

Scope:
- Configure WebApplicationBuilder
- Configure controllers
- Configure middleware
- Configure health checks
- Configure Swagger/OpenAPI
- Configure correlation middleware
- Configure exception middleware
- Configure HTTPS/auth middleware order
- Configure standard response envelope

Validation:
dotnet test backend/C2.sln --filter "Category=ApiBaseline"
```

---

# BE-003 PROMPT — Clean Architecture Layer Contracts

```text
Implement ONLY:
BE-003 Clean Architecture Layer Contracts

Scope:
- Result pattern
- CQRS abstractions
- MediatR abstractions
- validation pipeline behavior
- logging pipeline behavior
- transaction pipeline behavior
- current user abstraction
- clock abstraction
- unit of work abstraction
- domain events

Validation:
dotnet test backend/C2.sln --filter "Category=Architecture"
```

---

# BE-004 PROMPT — Domain Entities

```text
Implement ONLY:
BE-004 Domain Entities

Scope:
- MRV
- MRVItem
- Workflow
- WorkflowStep
- Device
- SmartBox
- SmartBoxCompartment
- Amr
- AmrMission
- Robot
- RobotTask
- TelemetryEvent
- CommandLog
- Alert
- AuditLog
- OfflineQueueItem
- ReconciliationRecord

Include:
- enums
- value objects
- audit fields
- rowVersion
- validation methods

Validation:
dotnet test backend/C2.sln --filter "Category=Domain"
```

---

# BE-005 PROMPT — EF Core DbContext

```text
Implement ONLY:
BE-005 EF Core DbContext

Scope:
- C2DbContext
- entity configurations
- PostgreSQL provider
- indexes
- FK constraints
- concurrency configuration
- migrations
- design-time factory

Validation:
dotnet ef migrations list --project backend/src/C2.Infrastructure --startup-project backend/src/C2.Api
```

---

# BE-006 PROMPT — Authentication And RBAC

```text
Implement ONLY:
BE-006 Authentication And RBAC

Scope:
- JWT authentication
- refresh token support
- role policies
- RBAC
- auth endpoints
- security audit logging
- authorization middleware

Roles:
- Admin
- Supervisor
- WarehouseOperator
- ProductionUser
- MaintenanceEngineer

Validation:
dotnet test backend/C2.sln --filter "Category=Security"
```

---

# BE-007 PROMPT — Workflow State Machine

```text
Implement ONLY:
BE-007 Workflow State Machine

Scope:
- workflow states
- valid transitions
- invalid transition rejection
- workflow guards
- retry states
- recovery states
- concurrency checks
- audit integration

Validation:
dotnet test backend/C2.sln --filter "Category=WorkflowState"
```

---

# BE-008 PROMPT — Audit Logging

```text
Implement ONLY:
BE-008 Audit Logging

Scope:
- immutable audit logs
- command logs
- audit writer
- audit queries
- correlation propagation
- trace propagation
- security audit events
- retry audit events

Validation:
dotnet test backend/C2.sln --filter "Category=Audit"
```

---

# BE-009 PROMPT — MRV API

```text
Implement ONLY:
BE-009 MRV API

Scope:
- POST /api/mrvs
- GET /api/mrvs/{mrvId}
- MRV validators
- duplicate workflow prevention
- workflow creation
- audit logging
- standard envelope
- validation errors

Validation:
dotnet test backend/C2.sln --filter "Category=MRV"
```

---

# BE-010 PROMPT — Workflow APIs

```text
Implement ONLY:
BE-010 Workflow APIs

Scope:
- GET /api/workflows
- GET /api/workflows/{workflowId}
- retry workflow
- pause workflow
- resume workflow
- cancel workflow
- RBAC validation
- idempotency handling

Validation:
dotnet test backend/C2.sln --filter "Category=WorkflowApi"
```

---

# BE-011 PROMPT — Device Registry

```text
Implement ONLY:
BE-011 Device Registry

Scope:
- device registry
- device identity
- device status
- heartbeat
- offline detection
- device APIs
- online/offline transitions

Validation:
dotnet test backend/C2.sln --filter "Category=Devices"
```

---

# BE-012 PROMPT — Integration Adapter Contracts

```text
Implement ONLY:
BE-012 Integration Adapter Contracts

Scope:
- AB3 adapter contract
- SAP adapter contract
- Kardex adapter contract
- SmartBox adapter contract
- AMR adapter contract
- Robot adapter contract
- canonical DTOs
- simulator contracts

Validation:
dotnet test backend/C2.sln --filter "Category=AdapterContracts"
```

---

# BE-013 PROMPT — SmartBox Adapter

```text
Implement ONLY:
BE-013 SmartBox Adapter

Scope:
- SmartBox APIs
- open door command
- close door command
- status query
- SmartBox event handling
- heartbeat handling
- compartment validation
- event deduplication
- command logging

Validation:
dotnet test backend/C2.sln --filter "Category=SmartBox"
```

---

# BE-014 PROMPT — Messaging And Idempotency Infrastructure

```text
Implement ONLY:
BE-014 Messaging And Idempotency Infrastructure

Scope:
- RabbitMQ abstractions
- publisher/consumer contracts
- idempotency service
- retry metadata
- DLQ support
- worker registration

Validation:
dotnet test backend/C2.sln --filter "Category=Messaging"
```

---

# BE-015 PROMPT — AMR Adapter

```text
Implement ONLY:
BE-015 AMR Adapter

Scope:
- AMR APIs
- mission creation
- mission telemetry
- mission completion
- mission failure
- return-home workflow
- telemetry persistence
- command logging

Validation:
dotnet test backend/C2.sln --filter "Category=AMR"
```

---

# BE-016 PROMPT — Robot Adapter

```text
Implement ONLY:
BE-016 Robot Adapter

Scope:
- robot APIs
- packing task dispatch
- robot telemetry
- robot fault events
- task idempotency
- active task protection

Validation:
dotnet test backend/C2.sln --filter "Category=Robot"
```

---

# BE-017 PROMPT — SAP And Kardex Adapters

```text
Implement ONLY:
BE-017 SAP And Kardex Adapters

Scope:
- SAP inventory validation
- Kardex picking integration
- picking status handling
- timeout handling
- retry integration
- audit logging

Validation:
dotnet test backend/C2.sln --filter "Category=KardexSap"
```

---

# BE-018 PROMPT — Retry Worker

```text
Implement ONLY:
BE-018 Retry Worker

Scope:
- retry queue
- exponential backoff
- replay logic
- offline queue
- reconciliation
- escalation
- retry audit logging
- DLQ handling

Validation:
dotnet test backend/C2.sln --filter "Category=Recovery"
```

---

# BE-019 PROMPT — SignalR/WebSocket Integration

```text
Implement ONLY:
BE-019 SignalR/WebSocket Integration

Scope:
- SignalR hubs
- operations stream
- workflow stream
- telemetry stream
- authenticated hubs
- realtime publishers
- cache invalidation events
- persisted-state-first publishing

Validation:
dotnet test backend/C2.sln --filter "Category=Realtime"
```

---

# BE-020 PROMPT — Alert And Audit APIs

```text
Implement ONLY:
BE-020 Alert And Audit APIs

Scope:
- alert query APIs
- audit query APIs
- audit search
- alert acknowledgement
- RBAC protection
- correlation search support

Validation:
dotnet test backend/C2.sln --filter "Category=AuditApi"
```

---

# BE-021 PROMPT — Unit Tests

```text
Implement ONLY:
BE-021 Unit Tests

Scope:
- domain tests
- workflow tests
- MRV tests
- SmartBox tests
- AMR tests
- Robot tests
- retry tests
- authorization tests
- concurrency tests

Validation:
dotnet test backend/C2.sln --filter "Category!=Integration"
```

---

# BE-022 PROMPT — Integration Tests

```text
Implement ONLY:
BE-022 Integration Tests

Scope:
- API contract tests
- auth tests
- RBAC tests
- persistence tests
- idempotency tests
- retry tests
- SignalR tests
- recovery tests

Validation:
dotnet test backend/C2.sln --filter "Category=Integration"
```

---

# MASTER FRONTEND SLICE PROMPT TEMPLATE

```text
Act as a Senior React TypeScript Engineer.

Read FIRST:
- AGENT.md
- /ai-rules
- /specs
- /tasks/frontend-tasks.md

Implement ONLY:
[TASK_ID]

Requirements:
- React + TypeScript strict mode
- React Query
- React Router
- typed API models
- feature-based structure
- realtime-ready architecture

Rules:
- Do NOT implement future tasks
- No business logic in components
- No direct fetch inside components
- Handle loading/error/offline states
- Add tests

Deliver:
1. Changed files summary
2. New files created
3. Validation commands
4. Assumptions/blockers

Validation:
- build passes
- tests pass
- no TS errors
```

---

# FE-001 PROMPT — Vite Project Setup

```text
Implement ONLY:
FE-001 Vite Project Setup

Scope:
- Vite React TypeScript setup
- strict mode
- React Query
- React Router
- SignalR client
- test stack
- environment config

Validation:
npm run build --prefix frontend
```

---

# FE-002 PROMPT — App Shell And Layout

```text
Implement ONLY:
FE-002 App Shell And Layout

Scope:
- providers
- layout
- error boundary
- operational shell
- shared status colors

Validation:
npm run build --prefix frontend
```

---

# FE-003 PROMPT — Routing

```text
Implement ONLY:
FE-003 Routing

Scope:
- protected routes
- role routes
- workflow routes
- SmartBox routes
- AMR routes
- alert routes

Validation:
npm test --prefix frontend -- --run routes
```

---

# FE-004 PROMPT — Auth Flow

```text
Implement ONLY:
FE-004 Auth Flow

Scope:
- login
- refresh
- logout
- token handling
- RBAC route protection
- session handling
- auth hooks

Validation:
npm test --prefix frontend -- --run auth
```

---

# FE-005 PROMPT — API Type Generation

```text
Implement ONLY:
FE-005 API Type Generation

Scope:
- typed DTOs
- standard envelope
- enums
- auth models
- workflow models
- SmartBox models
- AMR models

Validation:
npm run typecheck --prefix frontend
```

---

# FE-006 PROMPT — API Client

```text
Implement ONLY:
FE-006 API Client

Scope:
- typed API client
- correlation/request IDs
- bearer token handling
- error normalization
- idempotency headers
- pagination support

Validation:
npm test --prefix frontend -- --run api
```

---

# FE-007 PROMPT — React Query Hooks

```text
Implement ONLY:
FE-007 React Query Hooks

Scope:
- workflow hooks
- SmartBox hooks
- AMR hooks
- auth hooks
- alert hooks
- safe optimistic updates

Validation:
npm test --prefix frontend -- --run queries
```

---

# FE-008 PROMPT — Realtime Client

```text
Implement ONLY:
FE-008 Realtime Client

Scope:
- SignalR client
- reconnect handling
- stale state handling
- realtime subscriptions
- cache invalidation
- event deduplication

Validation:
npm test --prefix frontend -- --run realtime
```

---

# FE-009 PROMPT — Dashboard

```text
Implement ONLY:
FE-009 Dashboard

Scope:
- workflow cards
- device status
- alert panel
- retry queue
- filters
- realtime updates
- low-clutter operational UX

Validation:
npm test --prefix frontend -- --run dashboard
```

---

# FE-010 PROMPT — Workflow Detail

```text
Implement ONLY:
FE-010 Workflow Detail

Scope:
- workflow timeline
- MRV details
- retry history
- escalation state
- audit events
- workflow actions

Validation:
npm test --prefix frontend -- --run workflows
```

---

# FE-011 PROMPT — Critical Action Confirmation

```text
Implement ONLY:
FE-011 Critical Action Confirmation

Scope:
- dangerous action confirmation
- retry confirmation
- cancel confirmation
- door override confirmation

Validation:
npm test --prefix frontend -- --run critical-action
```

---

# FE-012 PROMPT — Validation UX

```text
Implement ONLY:
FE-012 Validation UX

Scope:
- validation rendering
- blocked state UX
- retry state UX
- operational error UX

Validation:
npm test --prefix frontend -- --run validation
```

---

# FE-013 PROMPT — SMARTBox View

```text
Implement ONLY:
FE-013 SMARTBox View

Scope:
- SmartBox list
- SmartBox detail
- compartment state
- battery status
- door controls
- fault state
- RBAC-aware actions

Validation:
npm test --prefix frontend -- --run smartboxes
```

---

# FE-014 PROMPT — AMR View

```text
Implement ONLY:
FE-014 AMR View

Scope:
- AMR list
- mission state
- telemetry
- fault state
- battery/location

Validation:
npm test --prefix frontend -- --run amrs
```

---

# FE-015 PROMPT — Alert Panel

```text
Implement ONLY:
FE-015 Alert Panel

Scope:
- alert severities
- sticky critical alerts
- alert acknowledgement
- escalation display

Validation:
npm test --prefix frontend -- --run alerts
```

---

# FE-016 PROMPT — Production Collection Flow

```text
Implement ONLY:
FE-016 Production Collection Flow

Scope:
- collection UX
- assigned SmartBox
- collection confirmation
- blocked state UX
- delivery status

Validation:
npm test --prefix frontend -- --run collection
```

---

# FE-017 PROMPT — Shared Status And Telemetry Components

```text
Implement ONLY:
FE-017 Shared Status And Telemetry Components

Scope:
- status badges
- battery indicator
- offline indicator
- retry indicator
- fault indicator
- emergency banner

Validation:
npm test --prefix frontend -- --run components
```

---

# FE-018 PROMPT — Empty, Loading, Error, Stale States

```text
Implement ONLY:
FE-018 Empty, Loading, Error, Stale States

Scope:
- loading states
- empty states
- stale state markers
- reconnect state
- API unavailable state

Validation:
npm test --prefix frontend -- --run states
```

---

# FE-019 PROMPT — Frontend Unit And Component Tests

```text
Implement ONLY:
FE-019 Frontend Unit And Component Tests

Scope:
- auth tests
- RBAC tests
- realtime tests
- dashboard tests
- SmartBox tests
- AMR tests
- validation tests

Validation:
npm test --prefix frontend -- --run
```

---

# FE-020 PROMPT — Integration Test Fixtures And Mocks

```text
Implement ONLY:
FE-020 Integration Test Fixtures And Mocks

Scope:
- API fixtures
- websocket fixtures
- mock workflows
- mock SmartBoxes
- mock AMRs
- reconnect simulation

Validation:
npm test --prefix frontend -- --run fixtures
```

---

# FE-021 PROMPT — Accessibility And Operator Ergonomics Pass

```text
Implement ONLY:
FE-021 Accessibility And Operator Ergonomics Pass

Scope:
- keyboard navigation
- focus management
- status accessibility
- operator usability improvements

Validation:
npm test --prefix frontend -- --run accessibility
```

---

# FE-022 PROMPT — Build And Quality Gate

```text
Implement ONLY:
FE-022 Build And Quality Gate

Scope:
- typecheck
- production build
- protected route verification
- no direct fetch verification
- no any verification
- quality checklist

Validation:
npm run build --prefix frontend && npm test --prefix frontend -- --run
```
