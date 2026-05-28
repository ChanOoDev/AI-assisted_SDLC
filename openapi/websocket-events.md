# WebSocket Events

Project: C2 Central Management System  
Protocol: SignalR/WebSocket over WSS  
Source note: requested `_Prompt.md` files were not present; generated from `/specs/07-api-integration.md`, `/specs/08-data-model.md`, and `/specs/05-workflows.md`.

## Principles

- REST APIs request commands; WebSocket events report state.
- Command acknowledgement is not physical completion.
- Physical completion must be confirmed by device event, telemetry, or workflow transition.
- Every event carries `traceId`, `correlationId`, `eventId`, and `occurredAt`.
- Workflow events must be emitted only after state persistence and audit write.
- Device physical state wins during reconciliation conflicts.

## Channels

| Channel | Audience | Purpose |
| --- | --- | --- |
| `/ws/operations` | Operators, supervisors | Dashboard-level workflow, device, alert, delivery, retry updates |
| `/ws/workflows/{workflowId}` | Operators, supervisors | Detailed workflow timeline and state updates |
| `/ws/devices/{deviceId}/telemetry` | Operators, maintenance | Device-specific telemetry, heartbeat, battery, fault, mission events |

## Common Envelope

```json
{
  "eventId": "evt-001",
  "eventType": "workflow.updated",
  "traceId": "4b8f16fd-dcdc-4275-ae38-14b7f5981234",
  "correlationId": "60e7f4db-6562-4d67-a823-03553e3c1234",
  "workflowId": "WF-001",
  "deviceId": "SB-01",
  "occurredAt": "2026-05-28T10:30:00Z",
  "sequenceNo": 42,
  "data": {}
}
```

| Field | Required | Notes |
| --- | --- | --- |
| `eventId` | Yes | Unique event ID. |
| `eventType` | Yes | Dot-delimited event name. |
| `traceId` | Yes | Server trace ID. |
| `correlationId` | Yes | End-to-end workflow correlation ID. |
| `workflowId` | When applicable | Required for workflow-bound events. |
| `deviceId` | When applicable | Required for device-bound events. |
| `occurredAt` | Yes | ISO 8601 UTC timestamp. |
| `sequenceNo` | When available | Used for event ordering/deduplication. |
| `data` | Yes | Event-specific payload. |

## Event Catalog

### `workflow.updated`

Emitted when workflow state changes.

Channels:

- `/ws/operations`
- `/ws/workflows/{workflowId}`

Payload:

```json
{
  "workflowId": "WF-001",
  "mrvId": "MRV-001",
  "previousState": "PACKING_IN_PROGRESS",
  "currentState": "PACKED",
  "triggeredBy": "ROBOT-01",
  "retryCount": 0,
  "message": "Robot packing completed."
}
```

### `workflow.retry.updated`

Emitted when retry state changes.

Channels:

- `/ws/operations`
- `/ws/workflows/{workflowId}`

Payload:

```json
{
  "workflowId": "WF-001",
  "commandId": "CMD-001",
  "attempt": 2,
  "maxAttempts": 4,
  "nextRetryAt": "2026-05-28T10:30:15Z",
  "errorCode": "DEVICE_TIMEOUT",
  "status": "RETRY_PENDING"
}
```

### `workflow.reconciliation.required`

Emitted when C2 state conflicts with physical device state.

Channels:

- `/ws/operations`
- `/ws/workflows/{workflowId}`
- `/ws/devices/{deviceId}/telemetry`

Payload:

```json
{
  "workflowId": "WF-001",
  "deviceId": "SB-01",
  "c2State": "DOOR_CLOSED",
  "deviceState": "DOOR_OPEN",
  "resolutionStatus": "RECONCILIATION_REQUIRED",
  "message": "Physical device state differs from C2 state."
}
```

### `device.status.updated`

Emitted when a device changes operational status.

Channels:

- `/ws/operations`
- `/ws/devices/{deviceId}/telemetry`

Payload:

```json
{
  "deviceId": "AMR-01",
  "deviceType": "AMR",
  "previousStatus": "ONLINE",
  "currentStatus": "OFFLINE",
  "lastHeartbeatAt": "2026-05-28T10:29:00Z",
  "affectedWorkflowIds": ["WF-001"]
}
```

### `device.heartbeat.received`

Emitted for accepted heartbeat events.

Channels:

- `/ws/devices/{deviceId}/telemetry`

Payload:

```json
{
  "deviceId": "SB-01",
  "deviceType": "SMARTBOX",
  "batteryPct": 82,
  "status": "ONLINE",
  "receivedAt": "2026-05-28T10:30:00Z"
}
```

### `smartbox.door.updated`

Emitted when SMARTBox door physical state is confirmed.

Channels:

- `/ws/operations`
- `/ws/workflows/{workflowId}`
- `/ws/devices/{deviceId}/telemetry`

Payload:

```json
{
  "smartBoxId": "SB-01",
  "doorId": 1,
  "compartmentId": "C01",
  "doorState": "OPEN",
  "workflowId": "WF-001",
  "commandId": "CMD-OPEN-001"
}
```

Door states:

- `OPEN`
- `CLOSED`
- `OPENING`
- `CLOSING`
- `FAILED`

### `smartbox.compartment.updated`

Emitted when compartment assignment or occupancy changes.

Channels:

- `/ws/operations`
- `/ws/workflows/{workflowId}`
- `/ws/devices/{deviceId}/telemetry`

Payload:

```json
{
  "smartBoxId": "SB-01",
  "compartmentId": "C01",
  "state": "LOADED",
  "occupied": true,
  "assignedWorkflowId": "WF-001",
  "assignedMrvItemId": "MRI-001"
}
```

### `smartbox.battery.alert`

Emitted when SMARTBox battery crosses warning or critical threshold.

Channels:

- `/ws/operations`
- `/ws/devices/{deviceId}/telemetry`

Payload:

```json
{
  "smartBoxId": "SB-01",
  "batteryPct": 15,
  "severity": "HIGH",
  "message": "SMARTBox battery low."
}
```

### `amr.mission.updated`

Emitted when AMR mission status changes.

Channels:

- `/ws/operations`
- `/ws/workflows/{workflowId}`
- `/ws/devices/{deviceId}/telemetry`

Payload:

```json
{
  "amrId": "AMR-01",
  "missionId": "MSN-001",
  "workflowId": "WF-001",
  "missionType": "DELIVERY",
  "previousState": "PICKUP_IN_PROGRESS",
  "currentState": "DELIVERY_IN_PROGRESS",
  "batteryPct": 75,
  "location": {
    "x": 10,
    "y": 20,
    "label": "WAREHOUSE"
  }
}
```

### `amr.location.updated`

Emitted when AMR location telemetry is received.

Channels:

- `/ws/devices/{deviceId}/telemetry`

Payload:

```json
{
  "amrId": "AMR-01",
  "missionId": "MSN-001",
  "batteryPct": 75,
  "location": {
    "x": 10,
    "y": 20,
    "label": "ROUTE-A"
  }
}
```

### `robot.task.updated`

Emitted when robot packing task changes state.

Channels:

- `/ws/operations`
- `/ws/workflows/{workflowId}`
- `/ws/devices/{deviceId}/telemetry`

Payload:

```json
{
  "robotId": "ROBOT-01",
  "robotTaskId": "RT-001",
  "workflowId": "WF-001",
  "previousState": "PACKING",
  "currentState": "COMPLETED",
  "itemCode": "ITEM-001",
  "targetSmartBoxId": "SB-01",
  "targetCompartmentId": "C01"
}
```

### `robot.health.updated`

Emitted when robot health telemetry is received.

Channels:

- `/ws/devices/{deviceId}/telemetry`

Payload:

```json
{
  "robotId": "ROBOT-01",
  "status": "ONLINE",
  "cpuUsagePct": 42,
  "faultStatus": "NONE"
}
```

### `alert.created`

Emitted when an operational, security, device, or workflow alert is raised.

Channels:

- `/ws/operations`
- `/ws/workflows/{workflowId}` when workflow-bound
- `/ws/devices/{deviceId}/telemetry` when device-bound

Payload:

```json
{
  "alertId": "ALT-001",
  "workflowId": "WF-001",
  "deviceId": "SB-01",
  "severity": "CRITICAL",
  "alertType": "EMERGENCY_STOP",
  "message": "Emergency stop triggered.",
  "status": "OPEN",
  "requiresAcknowledgement": true
}
```

Severity values:

- `CRITICAL`
- `HIGH`
- `MEDIUM`
- `LOW`

### `alert.acknowledged`

Emitted when an alert is acknowledged.

Channels:

- `/ws/operations`
- `/ws/workflows/{workflowId}` when workflow-bound
- `/ws/devices/{deviceId}/telemetry` when device-bound

Payload:

```json
{
  "alertId": "ALT-001",
  "acknowledgedBy": "user01",
  "acknowledgedAt": "2026-05-28T10:35:00Z",
  "status": "ACKNOWLEDGED"
}
```

### `delivery.updated`

Emitted when delivery or collection state changes.

Channels:

- `/ws/operations`
- `/ws/workflows/{workflowId}`

Payload:

```json
{
  "workflowId": "WF-001",
  "smartBoxId": "SB-01",
  "amrId": "AMR-01",
  "deliveryState": "DELIVERED",
  "destination": "HANGAR-A",
  "collectionStatus": "COLLECTION_PENDING"
}
```

### `audit.record.created`

Emitted when a workflow-relevant audit record is created.

Channels:

- `/ws/workflows/{workflowId}`

Payload:

```json
{
  "auditId": "AUD-001",
  "entityType": "WORKFLOW",
  "entityId": "WF-001",
  "action": "STATE_CHANGED",
  "actorId": "ROBOT-01",
  "actorType": "DEVICE",
  "previousState": "PACKING_IN_PROGRESS",
  "newState": "PACKED",
  "occurredAt": "2026-05-28T10:30:00Z"
}
```

## Client Handling Requirements

- Treat WebSocket events as notifications, not authorization proof.
- Re-fetch REST detail when a critical workflow, device, or alert event is received.
- Use `sequenceNo` where present to ignore stale or duplicate events.
- Show stale/offline state when connection drops.
- On reconnect, resubscribe to required channels and refresh active workflow/device views.

## Event Ordering And Deduplication

Consumers should order events by:

1. `workflowId`
2. `deviceId`
3. `occurredAt`
4. `sequenceNo` when available

Duplicate detection should use:

- `eventId`, or
- `deviceId` + `eventType` + `occurredAt` + `sequenceNo`

