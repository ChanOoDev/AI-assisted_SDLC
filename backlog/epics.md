# Epics

Project: C2 Central Management System  
Source note: requested `_Prompt.md` spec files were not present; generated from matching `/specs/*.md` files without `_Prompt`.

## EPIC-01 MRV Ingestion And Workflow Creation

**Goal:** Receive AB3/UM MRV payloads, validate them, prevent duplicate active workflows, and create auditable C2 workflows.

**Business Value:** Starts automation from the authoritative MRV source and removes manual workflow creation.

**Scope:** MRV API, payload validation, duplicate MRV handling, workflow creation, initial audit record.

**Priority:** Critical

**Depends On:** Core workflow model, audit logging, API validation.

## EPIC-02 Central Workflow Orchestration

**Goal:** Orchestrate MRV lifecycle states from received through completed, including retry, pause, resume, cancellation, and manual intervention states.

**Business Value:** Makes C2 the single operational authority for warehouse automation workflows.

**Scope:** workflow state machine, transition validation, workflow detail, workflow control actions.

**Priority:** Critical

**Depends On:** EPIC-01, audit logging, domain rules.

## EPIC-03 Inventory And Kardex Integration

**Goal:** Validate requested items through SAP/stock control and trigger Kardex picking through an adapter.

**Business Value:** Ensures only valid and available inventory enters automated picking and downstream handling.

**Scope:** SAP validation adapter, Kardex picking adapter, picking status handling, timeout/retry behavior.

**Priority:** Critical

**Depends On:** EPIC-01, EPIC-02, integration adapter contracts.

## EPIC-04 Mobile Manipulator Packing

**Goal:** Dispatch robot packing tasks and process robot completion, health, and fault events.

**Business Value:** Automates the packing step and reduces manual handling for eligible single-label items.

**Scope:** robot task dispatch, item handling validation, packing status events, robot fault handling.

**Priority:** Critical

**Depends On:** EPIC-02, EPIC-03, device registry.

## EPIC-05 SMARTBox Operations

**Goal:** Assign SMARTBox compartments, open/close doors, track occupancy, and process heartbeat/fault/battery events.

**Business Value:** Enables controlled, traceable item loading and collection using SMARTBox compartments.

**Scope:** compartment assignment, door commands, telemetry events, emergency stop handling, offline behavior.

**Priority:** Critical

**Depends On:** EPIC-02, EPIC-04, device registry, audit logging.

## EPIC-06 AMR Delivery

**Goal:** Dispatch AMR pickup/delivery missions, process mission status, and trigger return-home flow.

**Business Value:** Automates material delivery from warehouse to destination while maintaining realtime status.

**Scope:** AMR mission assignment, telemetry, mission completion, mission failure, return-home.

**Priority:** Critical

**Depends On:** EPIC-02, EPIC-05, device registry.

## EPIC-07 Production Collection

**Goal:** Notify production users, authenticate collection, open assigned compartment, confirm collection, and complete workflow.

**Business Value:** Closes the delivery loop with accountable user confirmation and traceability.

**Scope:** collection notification, user authentication, compartment access, GI label scan confirmation, completion audit.

**Priority:** Critical

**Depends On:** EPIC-05, EPIC-06, authentication/RBAC.

## EPIC-08 Realtime Monitoring Dashboard

**Goal:** Provide live workflow, device, delivery, retry, and alert visibility for operators and supervisors.

**Business Value:** Replaces manual monitoring with centralized operational visibility and faster exception response.

**Scope:** operations dashboard, workflow detail, SMARTBox view, AMR view, alert panel, realtime updates.

**Priority:** Critical

**Depends On:** workflow APIs, device telemetry, alert events, WebSocket/SignalR channel.

## EPIC-09 Retry, Recovery, Offline And Escalation

**Goal:** Preserve workflow state, retry transient failures, detect offline devices, reconcile state, and escalate unrecoverable issues.

**Business Value:** Protects operational continuity and prevents duplicate or unsafe device actions.

**Scope:** retry policy, idempotency, offline queue, reconciliation, escalation alerts, manual intervention.

**Priority:** Critical

**Depends On:** EPIC-02, EPIC-04, EPIC-05, EPIC-06, audit logging.

## EPIC-10 Security, Audit And Governance

**Goal:** Enforce JWT authentication, RBAC, secure system/device access, and immutable audit trails.

**Business Value:** Ensures only authorized users and systems can perform sensitive operational actions.

**Scope:** JWT, RBAC roles, device identity, command authorization, security events, immutable audit search.

**Priority:** Critical

**Depends On:** platform foundation.

