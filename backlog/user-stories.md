# User Stories

Project: C2 Central Management System  
Source note: requested `_Prompt.md` spec files were not present; generated from matching `/specs/*.md` files without `_Prompt`.

## US-001 Receive Valid MRV Payload

**User Story:** As AB3/UM, I want to submit a valid MRV JSON payload to C2 so that an automation workflow is created without manual entry.

**Business Value:** Removes manual workflow creation and starts the end-to-end automation process from the authoritative MRV source.

**Acceptance Criteria:**
- Given a valid MRV payload, when C2 receives it, then C2 validates the payload.
- Then C2 creates an MRV record and workflow ID.
- Then workflow state becomes `VALIDATED`.
- Then an audit log is created with correlation ID and source system.

**Dependencies:** EPIC-01, API baseline, workflow state model, audit logging.

**Priority:** Critical

**Test Notes:** Cover valid payload, required fields, standard response envelope, audit creation, response time under 2 seconds.

## US-002 Reject Invalid MRV Payload

**User Story:** As a warehouse operator, I want invalid MRV payloads rejected so that incomplete or unsafe workflows are not started.

**Business Value:** Prevents bad input from causing downstream automation errors.

**Acceptance Criteria:**
- Given an MRV payload missing MRV ID, timestamp, items, quantity, or destination, when submitted, then C2 rejects it.
- Then no workflow is created.
- Then validation errors are returned in the standard error response.
- Then the rejection is logged for traceability.

**Dependencies:** US-001, validation rules.

**Priority:** Critical

**Test Notes:** Test each missing mandatory field, malformed JSON, invalid item quantity, and error envelope.

## US-003 Prevent Duplicate Active MRV Workflow

**User Story:** As a warehouse supervisor, I want duplicate MRV submissions blocked so that the same request cannot create multiple active workflows.

**Business Value:** Prevents duplicate picking, packing, delivery, and audit inconsistency.

**Acceptance Criteria:**
- Given an MRV already has an active workflow, when the same MRV is submitted again, then C2 rejects the duplicate.
- Then the original workflow remains unchanged.
- Then the duplicate attempt is audited.

**Dependencies:** US-001, database uniqueness rule, workflow active-state definition.

**Priority:** Critical

**Test Notes:** Test same `mrvId` and source system, concurrent duplicate requests, audit record, and no duplicate workflow rows.

## US-004 Validate Inventory Before Orchestration

**User Story:** As C2, I want to validate requested items with SAP/stock control before orchestration so that only available inventory proceeds.

**Business Value:** Avoids robot and delivery activity for unavailable or invalid materials.

**Acceptance Criteria:**
- Given a validated MRV, when inventory validation is triggered, then C2 calls the SAP/stock control adapter.
- If inventory is available, then workflow progresses to picking.
- If inventory is unavailable, then workflow enters an exception state and alerts the operator.
- Then all validation results are audited.

**Dependencies:** US-001, US-003, SAP adapter contract.

**Priority:** Critical

**Test Notes:** Test available, unavailable, adapter timeout, retryable failure, and non-retryable validation failure.

## US-005 Trigger Kardex Picking

**User Story:** As a warehouse operator, I want C2 to trigger Kardex picking after inventory validation so that requested items are prepared for robot packing.

**Business Value:** Connects MRV workflow to automated picking without manual coordination.

**Acceptance Criteria:**
- Given inventory validation succeeds, when workflow enters picking stage, then C2 sends a picking request to Kardex.
- Then C2 receives picking status updates.
- Then workflow progresses when picking completes.
- Then timeout and retry handling are applied.

**Dependencies:** US-004, Kardex adapter contract, retry policy.

**Priority:** Critical

**Test Notes:** Test request mapping, picking completed event, timeout, retry attempts, and audit trail.

## US-006 Enforce Robot Handling Constraints

**User Story:** As a warehouse operator, I want C2 to validate robot handling constraints so that unsupported items are routed to manual handling.

**Business Value:** Prevents robot failure and unsafe handling of unsuitable items.

**Acceptance Criteria:**
- Given requested items exceed single-label, 25x25x5 cm, or 1-2 kg limits, when packing is evaluated, then C2 marks them unsuitable for robot handling.
- Then workflow does not dispatch an unsupported robot task.
- Then operator visibility and audit record are created.

**Dependencies:** US-004, item attributes, robot validation rules.

**Priority:** Critical

**Test Notes:** Test boundary values, invalid size, invalid weight, multi-label items, and manual intervention path.

## US-007 Dispatch Robot Packing Task

**User Story:** As C2, I want to dispatch packing tasks to the Mobile Manipulator so that eligible items are packed and GI-labeled.

**Business Value:** Automates a manual packing step and improves workflow consistency.

**Acceptance Criteria:**
- Given picking is complete and item is robot-eligible, when C2 dispatches packing, then the robot receives task details.
- Then workflow moves to `PACKING_IN_PROGRESS`.
- When robot signals completion, then workflow moves to `PACKED`.
- Then command and completion events are audited.

**Dependencies:** US-005, US-006, robot adapter, command log.

**Priority:** Critical

**Test Notes:** Test dispatch payload, completion event, fault event, duplicate command handling, and audit records.

## US-008 Handle Robot Packing Failure

**User Story:** As a warehouse operator, I want robot packing failures to pause and escalate safely so that workflow state is preserved.

**Business Value:** Reduces operational disruption and supports human recovery.

**Acceptance Criteria:**
- Given robot sends a fault event during packing, when C2 receives it, then workflow enters `RETRY_PENDING` or equivalent failure path.
- Then retry is attempted for recoverable failures.
- If retry limit is exceeded, then workflow enters `MANUAL_INTERVENTION`.
- Then operator alert and audit records are created.

**Dependencies:** US-007, retry engine, alerting.

**Priority:** Critical

**Test Notes:** Test fault event, retry count, max retry escalation, offline robot, and preserved workflow state.

## US-009 Assign SMARTBox Compartment

**User Story:** As C2, I want to assign one available SMARTBox compartment per item so that delivery storage is controlled and traceable.

**Business Value:** Prevents compartment conflicts and enables item-level traceability.

**Acceptance Criteria:**
- Given an item is packed, when C2 assigns a compartment, then the compartment must exist, be unoccupied, operational, and not faulted.
- Then the item is linked to one SMARTBox, one compartment, and one delivery workflow.
- Then conflicting active assignments are rejected.

**Dependencies:** US-007, SMARTBox registry, compartment status.

**Priority:** Critical

**Test Notes:** Test available compartment, occupied compartment, faulted SMARTBox, concurrent assignment, and audit.

## US-010 Open And Close SMARTBox Door

**User Story:** As C2, I want to open and close assigned SMARTBox doors so that robot loading and user collection can happen safely.

**Business Value:** Enables automated loading and controlled collection with traceable door operations.

**Acceptance Criteria:**
- Given a valid assigned compartment, when C2 sends open/close command, then command is logged with correlation ID.
- Door command requires valid door ID, SMARTBox online, and no emergency stop.
- C2 waits for door event confirmation before advancing workflow.
- Duplicate door commands are deduplicated.

**Dependencies:** US-009, command logging, SMARTBox adapter.

**Priority:** Critical

**Test Notes:** Test open, close, duplicate command, offline SMARTBox, emergency stop, and command ACK versus physical event.

## US-011 Process SMARTBox Telemetry And Faults

**User Story:** As a maintenance engineer, I want SMARTBox heartbeat, battery, occupancy, fault, and emergency events visible so that I can maintain uptime.

**Business Value:** Improves operational visibility and reduces undetected device failure.

**Acceptance Criteria:**
- Given SMARTBox sends telemetry, when C2 receives valid event data, then device state is updated.
- Battery alerts, faults, emergency stop, boot, door opened, and door closed events are persisted.
- Invalid telemetry is rejected and logged.
- Missing heartbeat marks SMARTBox offline.

**Dependencies:** US-009, telemetry validation, device registry.

**Priority:** Critical

**Test Notes:** Test each supported event type, invalid payload, heartbeat timeout, offline state, and dashboard event emission.

## US-012 Dispatch AMR Delivery Mission

**User Story:** As C2, I want to assign AMR delivery missions for loaded SMARTBoxes so that materials reach the destination automatically.

**Business Value:** Automates the transport step and reduces manual delivery effort.

**Acceptance Criteria:**
- Given SMARTBox is ready for delivery, when AMR is online with sufficient battery and no fault, then C2 dispatches a delivery mission.
- Then workflow moves to `DELIVERY_IN_PROGRESS`.
- Mission must not duplicate for same workflow, SMARTBox, and mission type.
- Then command is logged and audited.

**Dependencies:** US-010, AMR registry, AMR adapter, command idempotency.

**Priority:** Critical

**Test Notes:** Test valid dispatch, low battery, faulted AMR, offline AMR, duplicate mission, and audit.

## US-013 Process AMR Mission Completion

**User Story:** As a warehouse operator, I want AMR mission status updates processed in realtime so that delivery progress is accurate.

**Business Value:** Provides visibility and allows timely downstream collection notification.

**Acceptance Criteria:**
- Given AMR sends mission status, when C2 receives it, then mission and workflow state are updated.
- When delivery completes, then workflow moves to `DELIVERED` and return-home workflow is triggered.
- Battery, GPS/location, safety alerts, and mission status are available for monitoring.

**Dependencies:** US-012, AMR telemetry/event handling, workflow state machine.

**Priority:** Critical

**Test Notes:** Test mission completed, mission failed, telemetry updates, return-home trigger, and event ordering.

## US-014 Notify Production User For Collection

**User Story:** As a production user, I want to be notified when items are ready for collection so that I can collect them promptly.

**Business Value:** Reduces waiting time and closes the delivery loop faster.

**Acceptance Criteria:**
- Given delivery is completed, when workflow enters collection pending, then C2 notifies the assigned production user.
- Notification includes assigned SMARTBox, compartment, and collection status.
- Collection overdue triggers reminder or escalation.

**Dependencies:** US-013, user mapping, notification channel.

**Priority:** Critical

**Test Notes:** Test delivery completed notification, retrieval pending notification, overdue reminder, and audit.

## US-015 Authenticate And Confirm Collection

**User Story:** As a production user, I want to authenticate and confirm collection so that C2 records accountable item retrieval.

**Business Value:** Ensures traceable handoff and prevents unauthorized collection.

**Acceptance Criteria:**
- Given item is delivered, when user authenticates, then C2 verifies the user can collect the assigned item.
- Then assigned compartment opens.
- User confirms collection and GI label scan.
- Door closes and workflow moves to `COMPLETED`.
- User action and workflow completion are audited.

**Dependencies:** US-014, JWT/RBAC, SMARTBox door control.

**Priority:** Critical

**Test Notes:** Test authorized user, unauthorized user, missing GI scan, door close confirmation, and final workflow audit.

## US-016 View Realtime Operations Dashboard

**User Story:** As a warehouse operator, I want a realtime dashboard so that I can monitor workflows, devices, deliveries, alerts, and offline systems without manual refresh.

**Business Value:** Provides centralized operational visibility and faster exception response.

**Acceptance Criteria:**
- Given workflows or devices change state, when dashboard is open, then updates appear in realtime.
- Dashboard shows active workflows, robot status, AMR status, SMARTBox status, delivery progress, alerts, offline systems, and retry queue.
- Dashboard state is accurate without manual refresh.

**Dependencies:** workflow events, device events, alert events, realtime channel.

**Priority:** Critical

**Test Notes:** Test workflow update, device offline, alert created, retry count update, and under 1 second realtime target.

## US-017 View Workflow Detail And Audit Timeline

**User Story:** As a supervisor, I want workflow detail with timeline and audit history so that I can understand status, ownership, retries, and issues.

**Business Value:** Improves accountability and incident investigation.

**Acceptance Criteria:**
- Given a workflow exists, when supervisor opens detail, then MRV details, current state, assigned devices, retry history, and audit events are visible.
- Invalid or blocked workflow state displays clear reason.
- Manual intervention status and escalation owner are visible when applicable.

**Dependencies:** US-001, US-008, US-016, audit search.

**Priority:** High

**Test Notes:** Test happy path timeline, failure timeline, audit event ordering, retry history, and RBAC visibility.

## US-018 Retry Recoverable Device Command

**User Story:** As C2, I want to retry recoverable device commands with backoff and idempotency so that transient failures do not stop workflows.

**Business Value:** Increases workflow completion success while avoiding duplicate physical actions.

**Acceptance Criteria:**
- Given timeout, temporary network failure, 5xx error, temporary offline, or no acknowledgement, when retry policy runs, then retries occur with configured backoff.
- Each retry includes idempotency and correlation IDs.
- Each retry attempt is logged.
- After max retry, workflow escalates to manual intervention.

**Dependencies:** command log, retry engine, idempotency rules, alerting.

**Priority:** Critical

**Test Notes:** Test eligible errors, non-retryable errors, retry sequence, duplicate dedupe, DLQ/escalation, and no retry flooding.

## US-019 Reconcile Device State After Reconnect

**User Story:** As a warehouse operator, I want C2 to reconcile device state after reconnect so that workflow resumes only when safe.

**Business Value:** Prevents stale C2 state from causing unsafe or duplicate commands after network interruption.

**Acceptance Criteria:**
- Given a device reconnects after offline state, when C2 detects reconnect, then C2 queries physical device state.
- C2 compares device state with last known workflow state.
- If state is consistent, workflow may resume.
- If conflict exists, workflow enters reconciliation required and alerts operator.
- Reconciliation is audited.

**Dependencies:** device registry, offline detection, recovery engine, telemetry adapter.

**Priority:** Critical

**Test Notes:** Test robot reconnect, SMARTBox reconnect, AMR reconnect, conflicting physical state, queued command replay blocked when unsafe.

## US-020 Enforce Role-Based Access Control

**User Story:** As a system administrator, I want role-based access control so that users only perform actions appropriate to their responsibilities.

**Business Value:** Protects critical device and workflow operations from unauthorized use.

**Acceptance Criteria:**
- Admin can manage users and configuration.
- Supervisor can monitor operations and approve escalations.
- Warehouse Operator can monitor, retry, recover, and acknowledge alerts.
- Production User can view assigned collection and confirm retrieval only.
- Maintenance Engineer can view device telemetry and trigger maintenance recovery.
- Unauthorized and forbidden access attempts are rejected and audited.

**Dependencies:** authentication, user roles, audit logging.

**Priority:** Critical

**Test Notes:** Test each role, forbidden actions, invalid token, missing token, route protection, and security audit event.

## US-021 Capture Immutable Audit Logs

**User Story:** As a supervisor, I want immutable audit records for operational activity so that every workflow, command, user action, retry, and exception is traceable.

**Business Value:** Provides accountability, troubleshooting, and compliance-ready traceability.

**Acceptance Criteria:**
- Workflow transitions log previous state, new state, timestamp, actor/system, workflow ID, and correlation ID.
- Device commands log payload, timestamp, result, retry attempts, and correlation ID.
- User actions and security events are logged.
- Standard users cannot modify or delete audit records.

**Dependencies:** audit model, command log, workflow state machine, RBAC.

**Priority:** Critical

**Test Notes:** Test workflow transition audit, command audit, user action audit, security audit, immutability, and search by workflow ID.

## US-022 Handle Emergency Stop Event

**User Story:** As a warehouse operator, I want emergency stop events to halt workflow actions so that safety-critical conditions are handled immediately.

**Business Value:** Protects people, devices, and materials during safety events.

**Acceptance Criteria:**
- Given emergency stop event is received, when C2 processes it, then active workflow command execution is halted.
- Then related device enters emergency state.
- Then operators are notified and acknowledgement is required.
- Recovery requires authorized manual action and audit.

**Dependencies:** SMARTBox/AMR/robot telemetry, alerting, RBAC, recovery flow.

**Priority:** Critical

**Test Notes:** Test event ingestion, workflow freeze, command blocking, required acknowledgement, authorization, and audit.

## US-023 Detect Collection Timeout

**User Story:** As a warehouse operator, I want collection timeout detection so that uncollected items are escalated and recovered.

**Business Value:** Prevents delivered materials from remaining unclaimed without operational visibility.

**Acceptance Criteria:**
- Given workflow is in collection pending beyond configured threshold, when timeout is detected, then reminder is sent.
- Then operator alert is raised.
- Then recovery or pickup workflow can be triggered after escalation.
- Timeout event is audited.

**Dependencies:** US-014, US-015, alerting, recovery workflow.

**Priority:** High

**Test Notes:** Test threshold expiry, reminder, escalation, manual recovery trigger, and audit.

## US-024 Monitor Device Health

**User Story:** As a maintenance engineer, I want to monitor robot, SMARTBox, and AMR health so that device issues can be handled before they block operations.

**Business Value:** Improves uptime and reduces workflow interruption.

**Acceptance Criteria:**
- Device health shows online/offline status, last heartbeat, fault status, battery where available, and active workflow impact.
- Critical battery prevents new missions and raises alert.
- Device faults are visible to maintenance users.

**Dependencies:** device registry, telemetry ingestion, dashboard.

**Priority:** High

**Test Notes:** Test low battery, offline, faulted, emergency, maintenance visibility, and affected workflows.

## US-025 Validate End-To-End MVP Workflow

**User Story:** As a warehouse supervisor, I want the full MRV-to-collection flow validated so that the MVP proves operational feasibility.

**Business Value:** Confirms the platform can deliver the core automation value promised for the POC.

**Acceptance Criteria:**
- Given valid MRV and available devices, when workflow runs, then it completes MRV validation, inventory, Kardex, robot packing, SMARTBox loading, AMR delivery, user collection, and audit logging.
- Realtime dashboard reflects all major state changes.
- No manual refresh is required.
- Workflow ends in `COMPLETED`.

**Dependencies:** US-001 through US-021.

**Priority:** Critical

**Test Notes:** Execute E2E happy path, verify all AC-001 through AC-009 coverage, audit chain, realtime updates, and no duplicate commands.

