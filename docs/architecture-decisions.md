# Architecture Decisions

Project: C2 Central Management System  
Date: 2026-05-28  
Status: Proposed baseline for MVP/POC

## Decision Summary

| Area | Decision |
| --- | --- |
| Backend stack | .NET 8, ASP.NET Core Web API, Clean Architecture, CQRS with MediatR, FluentValidation |
| Frontend stack | React with TypeScript strict mode, React Query, feature-based structure |
| Database | PostgreSQL as the primary operational and audit database |
| Messaging | RabbitMQ for durable asynchronous workflow, command, retry, and integration events |
| Realtime communication | SignalR over WebSocket for the C2 web application; vendor protocols wrapped by adapters |
| Deployment target | AWS ECS Fargate for containerized backend services and workers |
| Authentication | JWT access tokens, refresh tokens, RBAC, API keys for MVP system integration, mTLS/client credentials for production integrations |
| Logging | Structured JSON logging with correlation IDs, command logs, workflow logs, security logs, and immutable audit logs |
| Monitoring | AWS CloudWatch plus OpenTelemetry-ready metrics/traces and application health checks |
| Retry/recovery | Durable retry queue, exponential backoff, idempotency keys, optimistic concurrency, state reconciliation, manual escalation |

## Context

C2 is the centralized orchestration authority for MRV-to-delivery workflows across AB3/Ultramain, SAP, Kardex, Mobile Manipulator, SMARTBox, and OTSAW AMR/FMCS. The MVP prioritizes stable workflow execution, realtime visibility, retry/recovery, auditability, and integration reliability.

Key constraints from `/specs` and `/ai-rules`:

- C2 owns workflow state, task sequencing, command history, audit history, and recovery status.
- Devices own physical state such as door status, battery level, mission status, telemetry, and emergency stop status.
- Vendor integrations must use adapter layers.
- Commands and events must be separated; command acknowledgement is not physical completion.
- APIs must be REST/JSON with a standard response envelope.
- Realtime dashboard updates must be pushed without manual refresh.
- All critical actions require correlation IDs, idempotency, audit logging, retry limits, and state validation.
- Backend must use .NET 8, Clean Architecture, CQRS + MediatR, FluentValidation, async/await, structured logging, and optimistic concurrency.
- Frontend must use React TypeScript, React Query, RBAC-protected routes, clear operational states, and no business logic in components.
- JWT, RBAC, HTTPS/WSS, no secrets in source, and audit logging are mandatory.

## Backend Stack

### Decision

Use `.NET 8` with `ASP.NET Core Web API`, Clean Architecture, CQRS with `MediatR`, `FluentValidation`, dependency injection, centralized exception handling, and background worker services for workflow orchestration and retry processing.

### Rationale

.NET 8 is mandated by the project AI rules and fits the operational integration workload well: strongly typed APIs, mature background workers, SignalR support, good PostgreSQL support, and production-ready observability options. Clean Architecture keeps workflow logic isolated from controllers and vendor adapters, which is important because vendor APIs may change during the MVP.

CQRS with MediatR supports clear separation between commands such as MRV ingestion, SMARTBox door operations, AMR mission dispatch, and recovery actions, and queries such as dashboards, workflow detail, audit search, and telemetry views.

### Alternatives Considered

- Node.js/NestJS: strong realtime ecosystem, but conflicts with the required .NET 8 backend direction.
- Java/Spring Boot: mature enterprise stack, but adds delivery friction against the project rules and likely team conventions.
- Monolithic controller-service pattern: simpler initially, but too easy to mix orchestration, validation, persistence, and vendor API calls.

### Impact

- Backend implementation must follow API, Application, Domain, and Infrastructure layers.
- Controllers must remain thin.
- Workflow state machine logic belongs in the domain/application layer.
- Vendor systems must be hidden behind adapters.
- Background workers are required for retries and asynchronous command dispatch.

## Frontend Stack

### Decision

Use `React` with `TypeScript` strict mode, `React Query` for server state, feature-based modules, typed API clients, and realtime subscriptions for operational dashboards.

### Rationale

The UX requires realtime workflow visibility, device status, alerts, retry state, and role-specific operational actions. React with TypeScript supports a maintainable operational dashboard while keeping UI behavior explicit and testable. React Query handles loading, error, stale, and refetch states without pushing business logic into components.

### Alternatives Considered

- Angular: strong enterprise framework, but not aligned with the frontend rules.
- Blazor: close to the .NET backend, but not selected by the rules and less aligned with the specified React Query requirement.
- Plain JavaScript React: lower setup friction, but unacceptable for safety-critical operational workflows requiring strict typing.

### Impact

- UI must be feature-based, role-aware, and operationally focused.
- Business rules remain in backend/application logic, not React components.
- Screens must handle loading, error, empty, success, offline, retry, and escalation states.
- Realtime updates must drive dashboard, workflow detail, SMARTBox, AMR, device, and alert views.

## Database

### Decision

Use `PostgreSQL` as the primary relational database for workflows, MRVs, device registry, SMARTBox compartments, AMR missions, robot tasks, command logs, telemetry events, alerts, users, and immutable audit logs.

### Rationale

The data model is relational and consistency-sensitive. C2 must enforce unique active workflows per MRV, compartment assignment locks, idempotency keys, optimistic concurrency, state transitions, and searchable audit history. PostgreSQL provides strong transactional integrity, constraints, indexing, JSONB for raw vendor payloads, and reliable operational maturity.

### Alternatives Considered

- SQL Server: technically suitable, but the project stack identifies PostgreSQL.
- MongoDB/document database: useful for flexible telemetry payloads, but weaker fit for workflow consistency, uniqueness constraints, and relational audit queries.
- Time-series database only: useful for high-volume telemetry later, but not sufficient as the primary workflow database.

### Impact

- Use transactions for state validation, state update, audit write, and command record creation.
- Do not keep database transactions open during external device calls.
- Use row versioning/optimistic concurrency on Workflow, WorkflowStep, SMARTBoxCompartment, AMRMission, and RobotTask.
- Store raw integration payloads where needed for troubleshooting, replay, and audit traceability.
- Consider later archival or time-series storage if telemetry volume exceeds MVP expectations.

## Messaging

### Decision

Use `RabbitMQ` for durable asynchronous messaging between workflow orchestration, integration adapters, command dispatch, retry processing, telemetry/event ingestion, and alert creation.

### Rationale

C2 must avoid blocking API requests while waiting for external devices, must retry transient failures safely, and must preserve workflow state across temporary outages. RabbitMQ provides durable queues, acknowledgements, dead-letter queues, routing, back-pressure, and retry patterns suitable for device command dispatch and integration event processing.

### Alternatives Considered

- In-process background queues: simple, but not durable across service restarts and insufficient for workflow recovery.
- Redis Streams: viable for lightweight event streams, but RabbitMQ is a better fit for command queues, acknowledgements, dead-letter handling, and operational retry semantics.
- Kafka: strong event streaming platform, but heavier than needed for the MVP baseline and less focused on command/retry queues.
- AWS SQS/SNS: managed and durable, but RabbitMQ keeps local/on-prem and cloud deployment options more portable during MVP integration.

### Impact

- Command dispatch and retry must be asynchronous.
- Message handlers must be idempotent.
- Dead-letter queues must trigger alerts and manual intervention workflows.
- Message payloads must include traceId, correlationId, requestId, workflowId, and idempotency key where applicable.
- RabbitMQ failure becomes an operational dependency that must be monitored.

## Realtime Communication

### Decision

Use `SignalR` over secure WebSocket (`WSS`) for C2 GUI realtime updates. Use adapter-specific protocols for external systems, including REST/JSON, WebSocket/REST for AMR, JSON-over-TCP for SMARTBox, and ZMQ only inside the SMARTBox interface where required.

### Rationale

The web application requires sub-second dashboard updates for workflow state, device telemetry, alerts, delivery status, retry state, and offline indicators. SignalR fits the .NET backend stack and provides connection management and fallback behavior while exposing WebSocket-first realtime communication to the frontend.

### Alternatives Considered

- Raw WebSocket: workable, but requires more custom connection, group, and reconnection handling.
- Server-Sent Events: good for one-way streams, but less flexible for operational realtime interactions and targeted subscriptions.
- Polling: simpler, but fails the no-manual-refresh and sub-second operational visibility requirements.

### Impact

- Realtime channels should map to operations, workflow, device telemetry, and alerts.
- Backend must publish state changes only after state persistence and audit requirements are satisfied.
- Frontend must show stale/offline status and reconnection behavior.
- WebSocket access must be authenticated and role-aware.

## Deployment Target

### Decision

Deploy containerized services to `AWS ECS Fargate` for the MVP baseline.

### Rationale

AWS ECS Fargate is explicitly listed in the project stack and provides managed container hosting without Kubernetes operational overhead. It is suitable for the MVP because services can be separated into API, worker, realtime, and adapter workloads while still keeping deployment relatively simple.

### Alternatives Considered

- On-prem servers: may be required for final production due to warehouse network constraints, but deployment architecture is not finalized.
- Kubernetes/EKS: powerful for large-scale expansion, but too heavy for MVP unless platform requirements demand it.
- Single VM deployment: simple, but weaker for scaling, isolation, deployment consistency, and operational resilience.

### Impact

- Build all services as containers.
- Use environment-based configuration and managed secret storage.
- Plan private network connectivity to warehouse systems, VPN/static IP routes, and firewall rules.
- HA and DR still require detailed design once production network and SLA requirements are finalized.

## Authentication

### Decision

Use JWT access tokens with refresh tokens for web users, RBAC authorization for all user actions, API keys for MVP external system authentication, and mTLS or OAuth2 client credentials for production integrations. All user, system, and device identities must be registered and scoped.

### Rationale

Specs require JWT, RBAC, HTTPS/TLS, device identity, and secure command authorization. MVP integration may need API keys due to vendor constraints, but production should move toward stronger system-to-system authentication where vendors support it.

### Alternatives Considered

- Session-cookie-only authentication: viable for web apps, but less aligned with API and WebSocket integration requirements.
- API keys for all users and systems: too weak for role-based web access and auditability.
- Full enterprise SSO only: desirable later, but SSO requirements are not confirmed for MVP.

### Impact

- Roles must include Admin, Supervisor, Warehouse Operator, Production User, and Maintenance Engineer.
- Backend authorization is mandatory; frontend RBAC is only a usability layer.
- Critical commands require role validation, valid workflow state, confirmation, and audit logging.
- Secrets must be stored outside source control and never logged.
- MFA should be supported later for Admin, Supervisor, and maintenance override operations.

## Logging

### Decision

Use structured JSON application logging with correlation IDs, request IDs, workflow IDs, device IDs, and command IDs. Maintain separate immutable audit logs for workflow transitions, device commands, retries, escalations, manual overrides, authentication events, authorization failures, and configuration changes.

### Rationale

Traceability is a core product requirement. Operational teams must be able to diagnose failed workflows, vendor integration issues, duplicate commands, telemetry conflicts, and security events. Structured logs make those events searchable and usable by monitoring tools.

### Alternatives Considered

- Plain text logs: easy to start, but poor for correlation, filtering, dashboards, and incident analysis.
- Audit-only logging: insufficient for technical troubleshooting.
- Logging raw full payloads everywhere: useful for integration debugging, but risky for sensitive data and storage volume.

### Impact

- Every request and command must carry traceId/correlationId.
- Sensitive values, secrets, tokens, and unnecessary PII must not be logged.
- Audit logs must be immutable or tamper-resistant.
- Command logs must capture request payload, response payload, result, retry attempts, and idempotency key where appropriate.

## Monitoring

### Decision

Use AWS CloudWatch for MVP centralized logs, metrics, dashboards, alarms, and container health. Instrument services with OpenTelemetry-compatible traces and metrics so the platform can later integrate with tools such as Grafana, Prometheus, or a SIEM.

### Rationale

Monitoring must cover workflows, integrations, devices, retries, offline states, API latency, security events, and operational alerts. CloudWatch fits the AWS ECS Fargate deployment target and gives the MVP a pragmatic monitoring baseline while OpenTelemetry avoids locking observability design to one vendor.

### Alternatives Considered

- Prometheus/Grafana from day one: powerful, but additional operational setup for MVP.
- Vendor-specific APM only: quick to adopt, but can create lock-in and may not cover operational workflow metrics well.
- Application dashboard only: useful for operators, but insufficient for platform health, infrastructure metrics, and alerting.

### Impact

- All services need health endpoints and readiness/liveness signals.
- Monitor API latency, workflow duration, retry count, dead-letter messages, device heartbeat timeouts, WebSocket connections, authentication failures, and integration error rates.
- Operational alerts must be visible in the C2 dashboard and infrastructure alerts must notify support teams.
- Define alert severity levels aligned to Critical, High, Medium, and Low.

## Retry And Recovery Approach

### Decision

Use a durable retry and recovery model based on persisted workflow state, command logs, RabbitMQ retry/dead-letter queues, exponential backoff, idempotency keys, optimistic concurrency, offline queues, reconciliation records, and manual escalation after retry limits.

Default retry policy:

```text
Attempt 1: immediate
Attempt 2: after 5 seconds
Attempt 3: after 15 seconds
Attempt 4: after 30 seconds
Then escalate to MANUAL_INTERVENTION or equivalent exception state.
```

### Rationale

C2 coordinates physical systems where duplicate commands, stale state, and blind retries can create operational risk. Recovery must preserve workflow state, distinguish command acknowledgement from physical completion, deduplicate messages, and require reconciliation when device state conflicts with C2 workflow state.

### Alternatives Considered

- Synchronous retry inside API requests: simple, but blocks users, holds resources, and does not survive outages.
- Unlimited retry: unsafe and can flood devices or hide real faults.
- Manual-only recovery: operationally safe but too slow and inconsistent for the MVP goals.

### Impact

- Retryable errors include timeout, temporary network failure, 5xx error, temporary device offline, and missing acknowledgement.
- Non-retryable errors include invalid payload, unauthorized request, invalid device ID, invalid workflow state, invalid door ID, and permission denied.
- Every retry must be logged with workflowId, commandId, attempt number, error reason, timestamp, and final result.
- Reconnect recovery must query device state, reconcile with C2 state, block unsafe replay, and audit the resolution.
- Physical safety state wins over C2 workflow assumptions when conflicts occur.
- Operators must see retry status, retry count, retry ETA, blocked reason, and escalation owner in the UI.

## Cross-Cutting Impacts

- The MVP should be modular but not over-engineered: start with clear service boundaries and adapters, then split deployables only where operationally useful.
- AI must stay out of the MVP critical path and must not directly control robots, SMARTBox doors, AMR missions, emergency recovery, or safety workflows.
- Tests must cover domain rules, validators, CQRS handlers, authorization-sensitive behavior, API envelope/status codes, idempotency, retry handling, concurrency, and critical UI states.
- Architecture must preserve auditability before convenience: no fire-and-forget device command is allowed without command logging, correlation, result tracking, and recovery handling.
