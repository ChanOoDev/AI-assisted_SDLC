# C2 Database ERD

Project: C2 Central Management System  
Database target: PostgreSQL  
Source specs: `/specs/08-data-model.md`, `/specs/04-domain-rules.md`, `/specs/07-api-integration.md`

## Design Notes

- C2 owns workflow state, command history, audit history, and recovery state.
- AB3/UM owns MRV source data.
- SAP/stock control owns inventory validation.
- Devices own physical state.
- Audit logs are immutable and append-only.
- Key workflow entities use `row_version` for optimistic concurrency.
- Command APIs rely on `idempotency_key` and correlation IDs for retry safety.

## Mermaid ERD

```mermaid
erDiagram
    USER_ACCOUNT ||--o{ USER_SESSION : owns
    USER_ACCOUNT ||--o{ AUDIT_LOG : performs
    USER_ACCOUNT ||--o{ ALERT : acknowledges

    MRV ||--o{ MRV_ITEM : contains
    MRV ||--|| WORKFLOW : creates

    WORKFLOW ||--o{ WORKFLOW_STEP : has
    WORKFLOW ||--o{ COMMAND_LOG : issues
    WORKFLOW ||--o{ ALERT : raises
    WORKFLOW ||--o{ AUDIT_LOG : records
    WORKFLOW ||--o{ ROBOT_TASK : includes
    WORKFLOW ||--o{ AMR_MISSION : includes
    WORKFLOW ||--o{ OFFLINE_QUEUE : queues
    WORKFLOW ||--o{ RECONCILIATION_RECORD : reconciles

    DEVICE ||--o{ WORKFLOW_STEP : assigned_to
    DEVICE ||--o{ TELEMETRY_EVENT : emits
    DEVICE ||--o{ COMMAND_LOG : receives
    DEVICE ||--o{ ALERT : triggers
    DEVICE ||--o{ OFFLINE_QUEUE : queues
    DEVICE ||--o{ RECONCILIATION_RECORD : reconciles

    DEVICE ||--o| SMARTBOX : specializes
    DEVICE ||--o| AMR : specializes
    DEVICE ||--o| ROBOT : specializes

    SMARTBOX ||--o{ SMARTBOX_COMPARTMENT : contains
    SMARTBOX ||--o{ AMR_MISSION : transported_by

    SMARTBOX_COMPARTMENT }o--o| MRV_ITEM : stores
    SMARTBOX_COMPARTMENT }o--o| WORKFLOW : assigned_to
    SMARTBOX_COMPARTMENT ||--o{ ROBOT_TASK : targeted_by

    AMR ||--o{ AMR_MISSION : performs
    ROBOT ||--o{ ROBOT_TASK : performs

    MRV {
        uuid id PK
        string mrv_id UK
        string source_system
        string requester_id
        string destination
        timestamptz request_datetime
        string status
    }

    MRV_ITEM {
        uuid id PK
        uuid mrv_id FK
        string item_code
        string item_name
        int quantity
        string label_type
        numeric width_cm
        numeric height_cm
        numeric depth_cm
        numeric weight_kg
        string handling_type
    }

    WORKFLOW {
        uuid id PK
        uuid mrv_id FK
        string workflow_type
        string current_state
        string priority
        timestamptz started_at
        timestamptz completed_at
        string failed_reason
        bigint row_version
    }

    WORKFLOW_STEP {
        uuid id PK
        uuid workflow_id FK
        string step_name
        string state
        uuid assigned_device_id FK
        int retry_count
        bigint row_version
    }

    DEVICE {
        uuid id PK
        string device_code UK
        string device_type
        string device_name
        string status
        string location
        timestamptz last_heartbeat_at
        boolean is_active
    }

    SMARTBOX {
        uuid id PK
        uuid device_id FK
        string smartbox_code UK
        int battery_pct
        string connectivity_status
        string operational_status
    }

    SMARTBOX_COMPARTMENT {
        uuid id PK
        uuid smartbox_id FK
        int door_id
        string state
        boolean occupied_flag
        uuid assigned_workflow_id FK
        uuid assigned_mrv_item_id FK
        bigint row_version
    }

    AMR {
        uuid id PK
        uuid device_id FK
        string amr_code UK
        int battery_pct
        string operational_status
    }

    AMR_MISSION {
        uuid id PK
        uuid workflow_id FK
        uuid amr_id FK
        uuid smartbox_id FK
        string mission_type
        string mission_state
        bigint row_version
    }

    ROBOT {
        uuid id PK
        uuid device_id FK
        string robot_code UK
        string operational_status
    }

    ROBOT_TASK {
        uuid id PK
        uuid workflow_id FK
        uuid robot_id FK
        string task_type
        string task_state
        string item_code
        uuid target_smartbox_id FK
        uuid target_compartment_id FK
        bigint row_version
    }

    TELEMETRY_EVENT {
        uuid id PK
        uuid device_id FK
        string event_type
        string severity
        timestamptz occurred_at
        timestamptz received_at
        jsonb payload
        bigint sequence_no
    }

    COMMAND_LOG {
        uuid id PK
        uuid workflow_id FK
        uuid device_id FK
        string command_type
        string command_state
        uuid correlation_id
        uuid idempotency_key
        int retry_count
    }

    ALERT {
        uuid id PK
        uuid workflow_id FK
        uuid device_id FK
        string severity
        string alert_type
        string status
        uuid acknowledged_by FK
    }

    AUDIT_LOG {
        uuid id PK
        string entity_type
        string entity_id
        string action
        uuid actor_id FK
        string actor_type
        timestamptz occurred_at
        uuid correlation_id
    }

    OFFLINE_QUEUE {
        uuid id PK
        uuid workflow_id FK
        uuid device_id FK
        string operation_type
        string status
        int retry_count
    }

    RECONCILIATION_RECORD {
        uuid id PK
        uuid device_id FK
        uuid workflow_id FK
        string resolution_action
        string status
    }
```

