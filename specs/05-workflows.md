# HAPPY PATH

# HP-001 — End-to-End MRV Workflow

## Trigger

Production submits MRV request from AB3/UM.

---

## Workflow

### Step 1 — MRV Received

* AB3/UM sends MRV JSON to C2
* C2 validates payload
* C2 creates workflow instance

State:

```text id="h0e0kh"
RECEIVED → VALIDATED
```

---

### Step 2 — Inventory Validation

* SAP/Stock Control confirms inventory availability
* Kardex receives picking request

State:

```text id="rbzthh"
VALIDATED → PICKING_PENDING
```

---

### Step 3 — Kardex Picking

* Kardex outputs requested items
* C2 triggers Kardex workflow

State:

```text id="5k0v32"
PICKING_PENDING → PICKING_COMPLETED
```

---

### Step 4 — Robot Packing

* Mobile Manipulator receives task
* Robot verifies item
* Robot repacks item
* GI label applied
* Robot signals completion

State:

```text id="59j4j7"
PACKING_PENDING → PACKING_IN_PROGRESS → PACKED
```

---

### Step 5 — SMARTBox Loading

* C2 assigns compartment
* SMARTBox door opens
* Robot deposits item
* Door closes
* Occupancy updated

State:

```text id="l8slfy"
SMARTBOX_LOADING → SMARTBOX_LOADED
```

---

### Step 6 — AMR Delivery

* C2 assigns AMR mission
* AMR picks up SMARTBox
* AMR delivers to destination
* AMR signals delivery completion

State:

```text id="i44l6x"
READY_FOR_DELIVERY → DELIVERY_IN_PROGRESS → DELIVERED
```

---

### Step 7 — User Collection

* Production user notified
* User authenticates
* SMARTBox opens assigned compartment
* User collects item
* User confirms collection
* GI label scanned
* SMARTBox closes compartment

State:

```text id="b7s5n4"
COLLECTION_PENDING → COLLECTED → COMPLETED
```

---

# FAILURE PATH

# FP-001 — Robot Packing Failure

## Scenario

Robot unable to verify/repack item.

---

## Flow

1. Robot sends fault event
2. Workflow paused
3. Retry attempted
4. If retry fails:

   * escalate to operator
   * workflow enters MANUAL_INTERVENTION

State:

```text id="0m8fyq"
PACKING_IN_PROGRESS → RETRY_PENDING → MANUAL_INTERVENTION
```

---

# FP-002 — SMARTBox Door Failure

## Scenario

Door fails to open/close.

---

## Flow

1. SMARTBox sends fault event
2. Retry door operation
3. If failure persists:

   * mark compartment unavailable
   * escalate operator
   * reassign compartment if possible

State:

```text id="cif2ga"
SMARTBOX_LOADING → FAILED
```

---

# FP-003 — AMR Mission Failure

## Scenario

AMR unable to complete mission.

---

## Flow

1. AMR sends mission failure
2. Retry mission
3. If retry exceeded:

   * assign alternate AMR if available
   * escalate operator
   * preserve delivery state

State:

```text id="uh99gm"
DELIVERY_IN_PROGRESS → RETRY_PENDING → FAILED
```

---

# FP-004 — Network Failure

## Scenario

Subsystem disconnected during workflow.

---

## Flow

1. Detect heartbeat timeout
2. Mark subsystem OFFLINE
3. Freeze active operations
4. Queue pending commands
5. Trigger operational alert

State:

```text id="mhbq1y"
ACTIVE → OFFLINE → RECOVERY_PENDING
```

---

# OFFLINE FLOW

# OF-001 — Robot Offline

## Flow

1. Heartbeat timeout detected
2. Robot marked OFFLINE
3. Active mission paused
4. Workflow state persisted
5. Operator notified

Recovery:

* resume mission after reconnect
* or reassign workflow manually

---

# OF-002 — SMARTBox Offline

## Flow

1. SMARTBox heartbeat missing
2. Prevent new compartment assignment
3. Preserve compartment state
4. Queue pending commands

Recovery:

* synchronize door state after reconnect

---

# OF-003 — AMR Offline

## Flow

1. AMR disconnected
2. Prevent new mission assignment
3. Pause active delivery workflow
4. Preserve last known location

Recovery:

* reconnect AMR
* resume delivery
* or manual retrieval

---

# OF-004 — C2 Temporary Outage

## Flow

1. Subsystems continue local operation
2. Pending telemetry buffered if supported
3. C2 restores connectivity
4. State synchronization initiated
5. Workflow reconciliation executed

---

# RETRY LOGIC

# RL-001 — API Retry

## Retry Policy

* max retry: 3
* exponential backoff
* retry interval:

  * 5 sec
  * 15 sec
  * 30 sec

---

# RL-002 — Command Retry

Commands eligible for retry:

* SMARTBox open/close
* AMR mission dispatch
* robot workflow trigger
* telemetry sync

---

# RL-003 — Non-Retryable Errors

Do NOT retry:

* invalid payload
* unauthorized request
* invalid configuration
* unsupported command

Escalate immediately.

---

# RL-004 — Workflow Retry

Recoverable failures:

* transient network issue
* temporary API timeout
* temporary subsystem disconnect

Workflow state must persist during retry.

---

# RL-005 — Idempotency

All retryable operations must support:

* correlation ID
* duplicate detection
* idempotent execution

Prevent:

* duplicate missions
* duplicate door operations
* duplicate workflow transitions

---

# RECOVERY FLOW

# RF-001 — Workflow Recovery

## Trigger

Subsystem reconnects or transient issue resolved.

---

## Flow

1. Re-establish connection
2. Synchronize subsystem status
3. Reconcile workflow state
4. Resume pending operations
5. Log recovery event

State:

```text id="v9jyp8"
RECOVERY_PENDING → RESUMED
```

---

# RF-002 — Robot Recovery

## Flow

1. Robot reconnects
2. Retrieve active mission state
3. Verify operational health
4. Resume workflow if safe

Else:

* escalate operator

---

# RF-003 — SMARTBox Recovery

## Flow

1. Query door states
2. Synchronize occupancy
3. Validate compartment integrity
4. Resume pending operations

---

# RF-004 — AMR Recovery

## Flow

1. Retrieve mission state
2. Verify current location
3. Resume delivery if safe
4. Else return-home workflow

---

# RF-005 — Data Recovery

## Flow

1. Replay pending events
2. Reconcile workflow history
3. Validate audit integrity
4. Resolve state conflicts

---

# ESCALATION FLOW

# EF-001 — Operational Escalation

## Trigger Conditions

* retry limit exceeded
* workflow timeout
* subsystem offline
* repeated faults
* mission failure

---

## Escalation Levels

### Level 1 — Automated Alert

* dashboard alert
* warning notification
* operational log

---

### Level 2 — Operator Intervention

* warehouse operator notified
* manual workflow review required

---

### Level 3 — Maintenance Escalation

* maintenance engineer notified
* subsystem inspection required

---

### Level 4 — System Escalation

* supervisor/admin escalation
* workflow suspension
* operational incident tracking

---

# EF-002 — Safety Escalation

## Trigger

* emergency stop
* collision alert
* safety sensor trigger

---

## Flow

1. halt workflow immediately
2. stop command execution
3. notify operators
4. require manual acknowledgement
5. authorize controlled recovery

---

# EF-003 — Delivery Escalation

## Trigger

* overdue delivery
* collection timeout
* AMR mission failure

---

## Flow

1. notify production user
2. notify warehouse operator
3. attempt recovery workflow
4. manual delivery fallback if required

---

# EF-004 — Audit Escalation

## Trigger

* repeated workflow inconsistency
* duplicate execution detected
* unauthorized operation
* audit validation failure

---

## Flow

1. log security event
2. notify administrator
3. preserve immutable logs
4. lock suspicious workflow if required

---

# ESCALATION SLA RECOMMENDATION

| Severity | Response Time |
| -------- | ------------- |
| Critical | < 5 min       |
| High     | < 15 min      |
| Medium   | < 1 hour      |
| Low      | < 4 hours     |

---

# RECOVERY PRINCIPLES

## Workflow Preservation

Workflow state must never be lost during:

* retry
* reconnect
* failover
* recovery

---

## Safe Resume

Resume only after:

* subsystem validation
* state reconciliation
* operational safety verification

---

## Audit Integrity

All retries, failures, recoveries, and escalations must be logged with:

* correlation ID
* timestamp
* actor/system
* workflow ID
* recovery result
