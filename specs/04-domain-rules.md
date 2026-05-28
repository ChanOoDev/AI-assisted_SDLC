# BUSINESS RULES

## BR-001 — MRV Source Authority

AB3/Ultramain is the authoritative source for MRV requests.

C2 shall not manually create MRV workflows.

---

## BR-002 — Inventory Validation

SAP/Stock Control remains the authoritative inventory validation source.

C2 shall only orchestrate workflows after inventory confirmation.

---

## BR-003 — Workflow Ownership

C2 is the centralized orchestration authority for:

* workflow state
* robot coordination
* SMARTBox coordination
* AMR mission orchestration

---

## BR-004 — One Active Workflow per MRV

Each MRV shall map to one active orchestration workflow.

Duplicate active workflows for same MRV are not allowed.

---

## BR-005 — SMARTBox Assignment

Each requested item must be assigned to:

* one SMARTBox
* one compartment
* one delivery workflow

---

## BR-006 — Delivery Completion

Delivery workflow is considered completed only after:

* user collection confirmation
* GI label scan confirmation
* compartment closure confirmation

---

## BR-007 — Human Override

Operators may manually intervene when:

* robot fault occurs
* workflow timeout occurs
* delivery failure occurs
* safety event occurs

---

## BR-008 — Auditability

All operational actions must be auditable:

* workflow transitions
* device commands
* user actions
* exceptions
* retries

---

# VALIDATION RULES

## VR-001 — MRV Payload Validation

MRV payload must contain:

* MRV ID
* request timestamp
* item list
* quantity
* destination/project reference

Invalid payloads shall be rejected.

---

## VR-002 — Duplicate MRV Validation

Duplicate MRV requests with active workflow shall be rejected.

---

## VR-003 — Item Validation

Requested items must:

* exist in inventory
* have valid quantity
* be within robot handling limitation

---

## VR-004 — Robot Payload Constraints

Robot can only handle:

* single-label items
* max size: 25x25x5 cm
* max weight: 1–2 kg

Invalid items require manual handling.

---

## VR-005 — SMARTBox Validation

SMARTBox compartment must:

* exist
* not already occupied
* be operational
* not be faulted

---

## VR-006 — AMR Validation

AMR mission dispatch requires:

* AMR online
* sufficient battery
* no active fault
* mission queue availability

---

## VR-007 — User Authentication

User must authenticate before:

* collection operation
* retrieval confirmation
* manual override actions

---

## VR-008 — Door Operation Validation

Door operation commands require:

* valid door ID
* SMARTBox online
* no emergency stop active

---

## VR-009 — Telemetry Validation

Incoming telemetry messages must:

* contain valid timestamp
* contain valid device ID
* follow protocol schema

Invalid telemetry shall be logged and rejected.

---

# WORKFLOW RULES

# WR-001 — MRV Workflow Start

Workflow starts after:

* MRV received
* inventory validated
* workflow created successfully

---

# WR-002 — Packing Workflow

Robot packing workflow sequence:

1. receive packing task
2. verify item
3. repack item
4. apply GI label
5. signal completion

---

# WR-003 — SMARTBox Loading Workflow

SMARTBox workflow sequence:

1. assign compartment
2. open compartment
3. robot deposits item
4. close compartment
5. update occupancy state

---

# WR-004 — AMR Delivery Workflow

AMR workflow sequence:

1. assign mission
2. pickup SMARTBox
3. deliver to destination
4. signal delivery complete
5. return to home

---

# WR-005 — Collection Workflow

Collection workflow sequence:

1. notify production user
2. authenticate user
3. open assigned compartment
4. user collects item
5. confirm collection
6. close compartment
7. complete workflow

---

# WR-006 — Failure Recovery Workflow

On recoverable failure:

* retry operation
* preserve workflow state
* log retry attempts

If retry limit exceeded:

* escalate to operator
* mark workflow exception state

---

# WR-007 — Timeout Workflow

Timeout scenarios:

* robot no response
* SMARTBox no response
* AMR no response
* collection overdue

Timeouts trigger:

* alert
* escalation
* manual intervention workflow

---

# STATE TRANSITIONS

# MRV Workflow States

```text
RECEIVED
→ VALIDATED
→ PACKING_PENDING
→ PACKING_IN_PROGRESS
→ PACKED
→ SMARTBOX_LOADING
→ READY_FOR_DELIVERY
→ DELIVERY_IN_PROGRESS
→ DELIVERED
→ COLLECTION_PENDING
→ COLLECTED
→ COMPLETED
```

Failure States:

```text
FAILED
RETRY_PENDING
MANUAL_INTERVENTION
CANCELLED
```

---

# Robot States

```text
IDLE
→ ASSIGNED
→ PACKING
→ VERIFYING
→ LOADING
→ COMPLETED
```

Failure States:

```text
FAULTED
OFFLINE
EMERGENCY_STOP
```

---

# SMARTBox States

```text
AVAILABLE
→ RESERVED
→ LOADING
→ LOADED
→ DELIVERING
→ READY_FOR_COLLECTION
→ COLLECTION_IN_PROGRESS
→ AVAILABLE
```

Failure States:

```text
OFFLINE
FAULTED
LOW_BATTERY
EMERGENCY_STOP
```

---

# AMR States

```text
IDLE
→ ASSIGNED
→ PICKUP_IN_PROGRESS
→ DELIVERY_IN_PROGRESS
→ DELIVERED
→ RETURNING_HOME
→ IDLE
```

Failure States:

```text
OFFLINE
FAULTED
MISSION_FAILED
LOW_BATTERY
```

---

# EDGE CASES

## EC-001 — Duplicate MRV Submission

Scenario:
Same MRV submitted multiple times.

Handling:

* reject duplicate workflow
* log duplicate attempt

---

## EC-002 — Robot Offline During Packing

Scenario:
Robot disconnects mid-workflow.

Handling:

* pause workflow
* preserve workflow state
* escalate to operator

---

## EC-003 — SMARTBox Door Failure

Scenario:
Door fails to open/close.

Handling:

* retry command
* trigger fault alert
* require manual intervention

---

## EC-004 — AMR Delivery Failure

Scenario:
AMR unable to complete mission.

Handling:

* retry mission
* escalate to operator
* preserve delivery state

---

## EC-005 — Network Disconnection

Scenario:
Subsystem disconnected.

Handling:

* maintain last known state
* retry communication
* trigger operational alert

---

## EC-006 — User Does Not Collect Item

Scenario:
Collection timeout exceeded.

Handling:

* send reminder
* escalate to operator
* trigger pickup workflow after timeout

---

## EC-007 — Battery Critical

Scenario:
SMARTBox/AMR battery critical.

Handling:

* prevent new missions
* raise alert
* prioritize return/recharge workflow

---

## EC-008 — Emergency Stop Triggered

Scenario:
Emergency stop activated.

Handling:

* halt active workflow
* freeze commands
* require operator acknowledgement

---

## EC-009 — Invalid Telemetry Payload

Scenario:
Malformed telemetry received.

Handling:

* reject payload
* log validation failure
* continue workflow safely

---

## EC-010 — Workflow Race Condition

Scenario:
Concurrent conflicting updates received.

Handling:

* enforce centralized workflow lock
* apply idempotency validation
* preserve workflow consistency

---

# AUDIT RULES

## AR-001 — Immutable Audit Trail

Audit logs must be immutable.

Audit records cannot be modified or deleted by standard users.

---

## AR-002 — Workflow Transition Logging

All workflow state transitions must be logged with:

* timestamp
* workflow ID
* previous state
* new state
* triggering actor/system

---

## AR-003 — Device Command Logging

All commands sent to:

* robot
* SMARTBox
* AMR

must be logged with:

* payload
* timestamp
* command result
* correlation ID

---

## AR-004 — User Action Logging

All user actions must be logged:

* login
* collection confirmation
* manual override
* workflow intervention

---

## AR-005 — Failure Logging

All failures must capture:

* error code
* device ID
* workflow ID
* retry count
* timestamp

---

## AR-006 — Telemetry Logging

Critical telemetry shall be persisted:

* battery alerts
* fault events
* emergency stop events
* mission failures

---

## AR-007 — Security Audit Logging

Security-sensitive events must be logged:

* failed login
* unauthorized access
* permission violations
* API authentication failures

---

## AR-008 — Correlation ID Tracking

All workflow operations must use correlation IDs to support:

* traceability
* troubleshooting
* end-to-end workflow tracking

---

## AR-009 — Time Synchronization

All audit timestamps shall use centralized synchronized system time.

---

## AR-010 — Retention Policy

Audit logs must support configurable retention policy aligned with operational and compliance requirements.
