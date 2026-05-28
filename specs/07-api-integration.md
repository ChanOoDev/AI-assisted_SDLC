# INTEGRATION & API RULES — C2 CENTRAL MANAGEMENT SYSTEM

# API STANDARDS

## AS-001 — API Style

Use REST APIs for command/control and WebSocket for realtime status/events.

## AS-002 — Data Format

All APIs shall use JSON.

```http
Content-Type: application/json
Accept: application/json
```

## AS-003 — Naming Convention

Use clear resource-based naming.

```text
/api/workflows
/api/mrvs
/api/devices
/api/smartboxes
/api/amrs
/api/robots
```

## AS-004 — Standard Response Envelope

```json
{
  "success": true,
  "data": {},
  "message": "Operation completed",
  "traceId": "uuid",
  "error": null
}
```

## AS-005 — Standard Error Response

```json
{
  "success": false,
  "data": null,
  "message": "Operation failed",
  "traceId": "uuid",
  "error": {
    "code": "DEVICE_OFFLINE",
    "details": "SMARTBox is offline"
  }
}
```

## AS-006 — Correlation

Every command/API request shall include:

* `traceId`
* `correlationId`
* `requestId`
* `workflowId` where applicable

## AS-007 — Timestamp

Use ISO 8601 UTC for APIs.

```json
"timestamp": "2026-05-28T10:30:00Z"
```

For SmartBox protocol, support existing `timestamp_ms`.

---

# ENDPOINT CONTRACTS

## MRV Integration

### Receive MRV

```http
POST /api/mrvs
```

Request:

```json
{
  "mrvId": "MRV-001",
  "source": "AB3",
  "requester": "user01",
  "destination": "HANGAR-A",
  "items": [
    {
      "itemCode": "ITEM-001",
      "quantity": 1,
      "labelType": "single",
      "sizeCm": { "w": 25, "h": 5, "d": 25 },
      "weightKg": 1.5
    }
  ]
}
```

Response:

```json
{
  "success": true,
  "data": {
    "workflowId": "WF-001",
    "status": "RECEIVED"
  }
}
```

---

## Workflow APIs

### Get Workflow

```http
GET /api/workflows/{workflowId}
```

### Retry Workflow

```http
POST /api/workflows/{workflowId}/retry
```

### Pause Workflow

```http
POST /api/workflows/{workflowId}/pause
```

### Resume Workflow

```http
POST /api/workflows/{workflowId}/resume
```

### Cancel Workflow

```http
POST /api/workflows/{workflowId}/cancel
```

---

## Mobile Manipulator APIs

### Trigger Packing

```http
POST /api/robots/{robotId}/packing-tasks
```

Request:

```json
{
  "workflowId": "WF-001",
  "mrvId": "MRV-001",
  "itemCode": "ITEM-001",
  "quantity": 1,
  "targetSmartBoxId": "SB-01",
  "targetCompartmentId": "C01"
}
```

### Receive Packing Status

```http
POST /api/robots/{robotId}/events
```

Event:

```json
{
  "eventType": "PACKING_COMPLETED",
  "workflowId": "WF-001",
  "status": "COMPLETED"
}
```

---

## SMARTBox APIs

### Open Door

```http
POST /api/smartboxes/{smartBoxId}/doors/{doorId}/open
```

### Close Door

```http
POST /api/smartboxes/{smartBoxId}/doors/{doorId}/close
```

### Query Status

```http
GET /api/smartboxes/{smartBoxId}/status
```

### Receive Event

```http
POST /api/smartboxes/{smartBoxId}/events
```

Events:

```json
{
  "eventType": "DOOR_OPENED",
  "doorId": 1,
  "batteryPct": 82,
  "timestamp": "2026-05-28T10:30:00Z"
}
```

Supported mapped events:

* heartbeat
* door opened
* door closed
* battery alert
* fault
* emergency stop
* boot

---

## AMR APIs

### Assign Delivery Mission

```http
POST /api/amrs/{amrId}/missions
```

Request:

```json
{
  "workflowId": "WF-001",
  "missionType": "DELIVERY",
  "smartBoxId": "SB-01",
  "pickupLocation": "WAREHOUSE",
  "dropoffLocation": "HANGAR-A"
}
```

### Receive Mission Status

```http
POST /api/amrs/{amrId}/events
```

Event:

```json
{
  "eventType": "MISSION_COMPLETED",
  "workflowId": "WF-001",
  "missionId": "MSN-001",
  "batteryPct": 75,
  "location": {
    "x": 10,
    "y": 20
  }
}
```

---

## WebSocket Channels

### Operations Dashboard

```text
/ws/operations
```

Events:

* workflow.updated
* device.status.updated
* alert.created
* delivery.updated

### Device Telemetry

```text
/ws/devices/{deviceId}/telemetry
```

### Workflow Stream

```text
/ws/workflows/{workflowId}
```

---

# RETRY RULES

## RR-001 — Retryable Errors

Retry for:

* timeout
* temporary network failure
* 5xx error
* temporary device offline
* no acknowledgement received

## RR-002 — Non-Retryable Errors

Do not retry:

* invalid payload
* unauthorized request
* invalid device ID
* invalid workflow state
* invalid door ID
* permission denied

## RR-003 — Retry Policy

Default retry policy:

```text
Attempt 1: immediate
Attempt 2: after 5 seconds
Attempt 3: after 15 seconds
Attempt 4: after 30 seconds
```

After max retry:

```text
RETRY_PENDING → MANUAL_INTERVENTION
```

## RR-004 — Device Command Retry

Retryable commands:

* SMARTBox open/close
* AMR mission dispatch
* robot packing trigger
* status query

## RR-005 — Retry Audit

Each retry must log:

* workflowId
* commandId
* attempt number
* error reason
* timestamp
* final result

---

# IDEMPOTENCY RULES

## IR-001 — Idempotency Key

All command APIs must accept:

```http
Idempotency-Key: <uuid>
```

## IR-002 — Duplicate MRV

Same `mrvId` shall not create more than one active workflow.

## IR-003 — Command Deduplication

Duplicate command with same idempotency key shall return previous result.

## IR-004 — Workflow State Protection

State transition must only apply when current state is valid.

Example:

```text
DELIVERED → COLLECTION_PENDING = valid
COMPLETED → DELIVERY_IN_PROGRESS = invalid
```

## IR-005 — Mission Deduplication

AMR mission shall not be created twice for same:

* workflowId
* smartBoxId
* missionType

## IR-006 — Door Command Deduplication

Door command shall not be duplicated when same door is already:

* opening
* closing
* open
* closed

## IR-007 — Event Deduplication

Events must be deduplicated using:

* deviceId
* eventType
* timestamp
* sequenceNo where available

---

# AUTHENTICATION

## AUTH-001 — User Authentication

Use JWT-based authentication for web users.

## AUTH-002 — Authorization

Use RBAC.

Roles:

* Admin
* Warehouse Operator
* Production User
* Maintenance Engineer
* Supervisor

## AUTH-003 — System Authentication

External systems should authenticate using:

* API key for MVP, or
* mTLS/client credentials for production

## AUTH-004 — Device Authentication

Each device shall have:

* device ID
* registered identity
* allowed command scope

## AUTH-005 — Token Security

JWT shall:

* expire
* be signed
* include user role
* include user ID
* include permissions/claims

## AUTH-006 — Command Authorization

Only authorized roles can:

* retry workflow
* cancel workflow
* manually override device
* open/close SMARTBox door
* trigger recovery flow

---

# SYNCHRONIZATION RULES

## SYNC-001 — C2 as Source of Workflow Truth

C2 owns:

* workflow state
* task sequence
* command history
* audit history

## SYNC-002 — Device as Source of Physical Truth

Devices own:

* door actual state
* battery status
* mission status
* robot telemetry
* fault status

## SYNC-003 — State Reconciliation

On reconnect:

1. query device status
2. compare with C2 last known state
3. resolve conflict
4. update workflow state
5. log reconciliation result

## SYNC-004 — Heartbeat Monitoring

Heartbeat timeout shall mark device as offline.

Recommended timeout:

```text
Offline if no heartbeat within 2x expected heartbeat interval
```

## SYNC-005 — Event Ordering

Events must be processed by:

1. workflowId
2. deviceId
3. timestamp
4. sequence number if available

## SYNC-006 — Conflict Handling

If device state conflicts with C2 state:

* physical safety state wins
* workflow enters RECONCILIATION_REQUIRED
* operator alert is raised

## SYNC-007 — Offline Command Queue

When device offline:

* block safety-critical commands
* queue non-critical commands only when safe
* replay after reconciliation

## SYNC-008 — Time Synchronization

All systems should use synchronized UTC time.

SmartBox `cmd_req_time` shall be answered by C2/server with current epoch time.

## SYNC-009 — Realtime Dashboard Sync

Dashboard must subscribe to:

* workflow events
* device telemetry
* alert events
* audit events

## SYNC-010 — Audit Sync

All integration events must be written to audit log before workflow state is finalized.

---

# INTEGRATION PRINCIPLES

## IP-001 — Command and Event Separation

Commands request action. Events report actual state.

## IP-002 — Acknowledge Then Confirm

Command acknowledgement does not equal physical completion.

Example:

```text
cmd_open_door accepted ≠ door opened
evt_door_opened = physical confirmation
```

## IP-003 — Safe Failure

If state is uncertain:

* stop progression
* alert operator
* reconcile device state

## IP-004 — Loose Coupling

Vendor protocols should be wrapped by adapter services.

## IP-005 — Observable Integration

Every integration must expose:

* health status
* last message time
* error count
* retry count
* command history
