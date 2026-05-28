# ARCHITECTURE RULES

## AR-001 — C2 Owns Orchestration

C2 shall be the central workflow orchestration authority.

C2 owns:

- workflow state
- task sequence
- command history
- audit trail
- recovery status

---

## AR-002 — Devices Own Physical State

Physical device state must come from the device itself.

Examples:

- SMARTBox door state
- AMR mission status
- robot telemetry
- battery status
- emergency stop status

---

## AR-003 — Use Adapter Pattern for Vendor Systems

Each external system must be integrated through an adapter layer.

Adapters required for:

- AB3/UM
- SAP
- Kardex
- Mobile Manipulator
- SMARTBox
- OTSAW AMR/FMCS

Do not couple core workflow logic directly to vendor APIs.

---

## AR-004 — Event-Driven Workflow

Use event-driven workflow processing for:

- telemetry events
- workflow state changes
- device status updates
- alerts
- recovery events

---

## AR-005 — Command/Event Separation

Commands request action. Events confirm actual state.

Example:

```text
cmd_open_door accepted ≠ door opened
evt_door_opened = physical confirmation
```

---

## AR-006 — Workflow State Persistence

Every workflow state transition must be persisted before downstream command execution.

---

## AR-007 — Idempotent Integration

All external commands must support:

- correlation ID
- idempotency key
- retry-safe execution
- duplicate detection

---

## AR-008 — Observability by Design

Every service must expose:

- logs
- metrics
- traces
- health checks
- integration status

---

## AR-009 — MVP-First Architecture

MVP architecture must prioritize:

- stable workflow execution
- integration reliability
- auditability
- recovery capability

Avoid over-engineering.

---

# BACKEND RULES

## BE-001 — Clean Architecture

Backend shall follow layered architecture:

```text
API Layer
Application Layer
Domain Layer
Infrastructure Layer
```

---

## BE-002 — Domain-Centric Workflow

Workflow logic must live in domain/application layer, not controller layer.

Controllers must only:

- validate request
- call application service/mediator
- return response

---

## BE-003 — State Machine Enforcement

Workflow state transitions must be validated by centralized state machine rules.

Invalid transitions must be rejected.

---

## BE-004 — Command Handler Pattern

Use command handlers for:

- MRV ingestion
- workflow transition
- SMARTBox command
- AMR mission assignment
- retry/recovery operation

---

## BE-005 — Query Separation

Use query handlers/read models for:

- dashboard
- workflow detail
- audit history
- device telemetry
- reports

---

## BE-006 — Standard API Response

Use consistent response envelope:

```json
{
  "success": true,
  "data": {},
  "message": "OK",
  "traceId": "uuid",
  "error": null
}
```

---

## BE-007 — Transaction Boundary

Keep transactions short.

One transaction should cover:

- state validation
- state update
- audit write
- command record creation

Device command dispatch should not hold DB transaction open.

---

## BE-008 — Retry Queue

External command retry must be handled by background worker/queue, not blocking API request.

---

## BE-009 — Audit First

Write audit/command log before or during state change.

No critical action shall occur without audit trace.

---

## BE-010 — Optimistic Concurrency

Use version/rowVersion for:

- Workflow
- WorkflowStep
- SMARTBoxCompartment
- AMRMission
- RobotTask

---

# FRONTEND RULES

## FE-001 — Realtime UX

Frontend must subscribe to realtime updates for:

- workflow state
- device status
- alerts
- telemetry events

---

## FE-002 — Dashboard First

MVP frontend priority:

- operations dashboard
- workflow detail
- SMARTBox status
- AMR status
- alerts panel

---

## FE-003 — Role-Based UI

UI must only show actions allowed by user role.

Backend authorization remains mandatory.

---

## FE-004 — Clear Operational Status

Use clear statuses:

- Running
- Waiting
- Completed
- Failed
- Offline
- Manual Intervention Required

---

## FE-005 — Error Transparency

Errors must explain:

- what failed
- operational impact
- next action

Avoid raw technical errors.

---

## FE-006 — Offline Indicators

Frontend must show:

- offline devices
- last connected time
- affected workflows
- retry state

---

## FE-007 — Confirmation for Critical Actions

Require confirmation for:

- manual override
- retry after critical fault
- cancel workflow
- force door open/close

---

## FE-008 — No Hidden Workflow State

Operators must always see:

- current workflow state
- blocking reason
- assigned device
- retry count
- escalation status

---

# SECURITY RULES

## SR-001 — Secure by Default

All APIs and WebSockets must use:

- HTTPS
- WSS
- TLS
- authenticated access

---

## SR-002 — JWT + RBAC

Use JWT authentication and role-based authorization.

Roles:

- Admin
- Supervisor
- Warehouse Operator
- Production User
- Maintenance Engineer

---

## SR-003 — Least Privilege

Users and devices must receive only required permissions.

---

## SR-004 — Device Identity

Every device must have registered identity and allowed command scope.

---

## SR-005 — Protect Critical Commands

Critical commands require:

- authorized role
- valid workflow state
- confirmation
- audit logging

Examples:

- door open/close
- workflow cancel
- emergency recovery
- manual override

---

## SR-006 — Audit Security Events

Log:

- failed login
- unauthorized access
- permission violation
- token failure
- suspicious operation

---

## SR-007 — No Secrets in Code

Secrets must never be stored in:

- source code
- frontend bundle
- config committed to repository
- logs

---

## SR-008 — Input Validation

Validate all input:

- API payloads
- WebSocket messages
- device events
- query parameters
- file/config imports

---

# AI CONSTRAINTS

## AI-001 — AI Is Advisory Only

AI must not directly control:

- robots
- SMARTBox doors
- AMR missions
- emergency recovery
- safety workflows

---

## AI-002 — Human Approval Required

AI-generated recommendations require human approval before:

- operational action
- workflow override
- device command
- recovery decision

---

## AI-003 — No Autonomous Safety Decisions

AI must not decide:

- emergency stop recovery
- collision response
- safety override
- critical fault clearance

---

## AI-004 — Explainable Recommendations

AI outputs must provide:

- reason
- confidence level
- data used
- recommended next step

---

## AI-005 — No Training on Sensitive Logs Without Approval

Do not use production:

- telemetry logs
- user data
- audit logs
- incident data

for AI training without governance approval.

---

## AI-006 — Keep AI Out of MVP Critical Path

MVP shall not depend on AI for:

- workflow orchestration
- device command execution
- collection authorization
- safety decisions

AI may be considered in later phase for analytics/recommendations.

---

# FORBIDDEN PATTERNS

## FP-001 — Direct Vendor Coupling

Do not call vendor APIs directly from domain logic or frontend.

Use adapter services.

---

## FP-002 — Frontend-Only Authorization

Do not rely on UI hiding for security.

Backend must enforce authorization.

---

## FP-003 — Fire-and-Forget Commands Without Audit

Do not send device commands without:

- command log
- correlation ID
- result tracking
- audit record

---

## FP-004 — Long DB Transactions During Device Calls

Do not hold database transactions while waiting for:

- robot response
- SMARTBox response
- AMR mission response

---

## FP-005 — Blind Retry

Do not retry without:

- idempotency key
- retry limit
- backoff
- audit log

---

## FP-006 — State Update Without Validation

Do not update workflow state without state transition validation.

---

## FP-007 — Treat Command ACK as Completion

Do not treat accepted command as physical completion.

Wait for event/telemetry confirmation.

---

## FP-008 — Ignore Offline State

Do not continue workflow progression when required subsystem is offline.

---

## FP-009 — Store Raw Secrets

Do not store passwords, API keys, tokens, or certificates in logs/database plaintext.

---

## FP-010 — AI Autonomous Control

Do not allow AI to directly trigger physical device operations or safety-related decisions.

---

## FP-011 — Silent Failure

Do not fail silently.

All failures must:

- be logged
- update workflow state
- notify relevant users
- support recovery

---

## FP-012 — Manual Database Fix as Normal Process

Do not rely on direct DB updates for workflow recovery.

Recovery must be handled through controlled application workflows.
