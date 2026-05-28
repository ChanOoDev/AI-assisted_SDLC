# Database Migration Plan

Project: C2 Central Management System  
Database target: PostgreSQL  
Source specs: `/specs/08-data-model.md`, `/specs/04-domain-rules.md`, `/specs/07-api-integration.md`

## Migration Principles

- Use additive migrations where possible.
- Keep workflow state changes transactional and short.
- Do not hold database transactions while calling external devices.
- Every critical command/state change must write command/audit data.
- Use `row_version` for optimistic concurrency on workflow and device-operation tables.
- Use idempotency indexes for command replay safety.
- Audit records are append-only and protected by database triggers.

## Migration Sequence

| Phase | Migration | Scope | Validation |
| --- | --- | --- | --- |
| 001 | Extensions and security base | `pgcrypto`, users, sessions | users and sessions can be created |
| 002 | MRV base | `mrvs`, `mrv_items`, source uniqueness | duplicate source MRV blocked |
| 003 | Workflow core | `workflows`, `workflow_steps`, active MRV partial unique index | one active workflow per MRV |
| 004 | Device registry | `devices`, status and heartbeat indexes | device lookup by type/status |
| 005 | Device specializations | `smartboxes`, `smartbox_compartments`, `amrs`, `robots` | device subtype rows link to device |
| 006 | Missions and tasks | `amr_missions`, `robot_tasks`, active mission/task indexes | duplicate active mission/task blocked |
| 007 | Telemetry and commands | `telemetry_events`, `command_logs`, event dedupe, idempotency | duplicate command blocked |
| 008 | Alerts and audit | `alerts`, `audit_logs`, audit immutability triggers | audit cannot update/delete |
| 009 | Recovery data | `offline_queue`, `reconciliation_records` | reconnect/replay state persisted |
| 010 | Operational indexes | dashboard, audit, workflow, retry, telemetry indexes | key queries use indexes |
| 011 | Retention jobs | archive tables/jobs or scheduled cleanup procedures | retention policy dry run |

## Rollout Plan

1. Apply schema in a local development database.
2. Run migration smoke checks:
   - create MRV with items
   - create workflow
   - create device and subtype
   - create command log with idempotency key
   - create telemetry event
   - create audit record
3. Verify protected constraints:
   - duplicate active workflow for same MRV fails
   - duplicate command `device_id + idempotency_key` fails
   - duplicate active SMARTBox compartment assignment fails
   - audit update/delete fails
4. Apply migration to integration environment.
5. Run API integration tests against migrated schema.
6. Apply to UAT/MVP environment after backup and release approval.

## Foreign Key Strategy

- Use hard foreign keys for core operational relationships:
  - MRV to MRV items
  - MRV to workflow
  - workflow to steps, commands, alerts, missions, tasks, audit
  - device to telemetry, commands, alerts, reconciliation
  - device to SMARTBox/AMR/Robot specializations
- Avoid cascading deletes for operational and audit data.
- Use soft delete fields on mutable operational tables.
- Keep `audit_logs` immutable and non-soft-deleted.

## Index Strategy

Core indexes:

- `mrvs(source_system, mrv_id)` unique
- partial unique active workflow per MRV
- partial unique active SMARTBox compartment assignment
- `command_logs(device_id, idempotency_key)` unique
- telemetry dedupe by `device_id`, `event_type`, `occurred_at`, `sequence_no`
- workflow dashboard indexes on state, start time, correlation ID
- audit search indexes by workflow, MRV, device, actor, correlation, entity
- retry/offline indexes by queue status and queued time

## Concurrency Strategy

Use `row_version bigint` on:

- `workflows`
- `workflow_steps`
- `smartbox_compartments`
- `amr_missions`
- `robot_tasks`
- `command_logs`
- `offline_queue`
- `reconciliation_records`

Application update pattern:

```sql
UPDATE workflows
SET current_state = @next_state
WHERE id = @workflow_id
  AND row_version = @expected_row_version;
```

If no row is updated, treat as concurrency conflict and reload current state.

## Retention Strategy

| Data Type | Retention | Handling |
| --- | --- | --- |
| Active workflows | until completed/cancelled/failed | remain in operational tables |
| Completed workflows | 3-7 years | archive after operational lookup window |
| Failed workflows | 3-7 years | retain longer if incident-linked |
| Audit logs | minimum 7 years | immutable, searchable, exportable |
| Command logs | 3-7 years | failed/retry command logs 7 years |
| Raw telemetry | 30-90 days | partition or archive by month |
| Critical telemetry | 3-7 years | retain fault, battery, emergency, mission failure |
| Alerts | 1-3 years | critical alerts 3-7 years |
| Security logs | 1-3 years | access violations/admin actions up to 7 years |
| Offline queue | until resolved plus 90 days | archive replay history |
| Reconciliation records | 3-7 years | retain for incident traceability |

## Partitioning Recommendation

Start MVP without mandatory partitioning unless telemetry volume is high. Prepare for monthly partitions on:

- `telemetry_events`
- `audit_logs`
- `command_logs`

Partition trigger point:

- telemetry exceeds 1 million rows/month, or
- audit/command queries exceed agreed response targets.

## Backup And Recovery

- Daily full backup for MVP minimum.
- Point-in-time recovery recommended for production.
- Verify restore before UAT.
- Export immutable audit logs before destructive environment resets.
- Never repair workflows by manual database update as normal operation; use application recovery workflows.

## Data Quality Checks

Run these checks after every migration:

- orphan workflow steps
- orphan command logs
- workflows without MRV
- active duplicate MRV workflows
- active duplicate SMARTBox compartment assignments
- command logs without correlation ID
- audit logs without correlation ID
- telemetry without valid device or timestamp

Example:

```sql
SELECT mrv_id, COUNT(*)
FROM workflows
WHERE current_state NOT IN ('COMPLETED', 'FAILED', 'CANCELLED')
GROUP BY mrv_id
HAVING COUNT(*) > 1;
```

## Rollback Strategy

- Roll back code first when possible.
- Avoid dropping columns/tables in MVP migrations.
- For additive migrations, rollback by disabling new code path and leaving unused columns.
- For constraint migrations, validate in pre-production with production-like data before applying.
- For emergency rollback, restore from backup only with product/operations approval because workflow/audit continuity may be impacted.

