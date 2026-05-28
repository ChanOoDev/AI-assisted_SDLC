-- C2 Central Management System database schema
-- Target: PostgreSQL 15+
-- Source specs: 08-data-model.md, 04-domain-rules.md, 07-api-integration.md

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- =========================================================
-- Shared enum-like checks are implemented as text + CHECK
-- to keep early MVP migrations flexible while still bounded.
-- =========================================================

CREATE TABLE user_accounts (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    username varchar(150) NOT NULL UNIQUE,
    password_hash text,
    role varchar(50) NOT NULL CHECK (role IN ('Admin', 'Supervisor', 'WarehouseOperator', 'ProductionUser', 'MaintenanceEngineer')),
    department varchar(150),
    status varchar(30) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'LOCKED', 'DISABLED')),
    last_login_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    created_by uuid,
    updated_at timestamptz,
    updated_by uuid,
    deleted_at timestamptz,
    deleted_by uuid,
    is_deleted boolean NOT NULL DEFAULT false,
    row_version bigint NOT NULL DEFAULT 1
);

CREATE TABLE user_sessions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES user_accounts(id),
    refresh_token_hash text NOT NULL,
    expires_at timestamptz NOT NULL,
    revoked_at timestamptz,
    source_ip inet,
    user_agent text,
    created_at timestamptz NOT NULL DEFAULT now(),
    created_by uuid,
    updated_at timestamptz,
    updated_by uuid,
    deleted_at timestamptz,
    deleted_by uuid,
    is_deleted boolean NOT NULL DEFAULT false,
    row_version bigint NOT NULL DEFAULT 1
);

CREATE TABLE mrvs (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    mrv_id varchar(100) NOT NULL,
    source_system varchar(100) NOT NULL,
    requester_id varchar(150) NOT NULL,
    destination varchar(150) NOT NULL,
    request_datetime timestamptz NOT NULL,
    status varchar(50) NOT NULL DEFAULT 'RECEIVED',
    trace_id uuid,
    correlation_id uuid NOT NULL,
    request_id uuid,
    source_reference_id varchar(150),
    raw_payload jsonb,
    created_at timestamptz NOT NULL DEFAULT now(),
    created_by uuid,
    updated_at timestamptz,
    updated_by uuid,
    deleted_at timestamptz,
    deleted_by uuid,
    is_deleted boolean NOT NULL DEFAULT false,
    row_version bigint NOT NULL DEFAULT 1,
    CONSTRAINT uq_mrvs_source_mrv UNIQUE (source_system, mrv_id)
);

CREATE TABLE mrv_items (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    mrv_id uuid NOT NULL REFERENCES mrvs(id),
    item_code varchar(100) NOT NULL,
    item_name varchar(250),
    quantity integer NOT NULL CHECK (quantity > 0),
    label_type varchar(30) NOT NULL CHECK (label_type IN ('single', 'multiple')),
    width_cm numeric(10, 2),
    height_cm numeric(10, 2),
    depth_cm numeric(10, 2),
    weight_kg numeric(10, 3),
    handling_type varchar(30) NOT NULL DEFAULT 'ROBOT' CHECK (handling_type IN ('ROBOT', 'MANUAL')),
    trace_id uuid,
    correlation_id uuid,
    request_id uuid,
    workflow_id uuid,
    source_system varchar(100),
    source_reference_id varchar(150),
    created_at timestamptz NOT NULL DEFAULT now(),
    created_by uuid,
    updated_at timestamptz,
    updated_by uuid,
    deleted_at timestamptz,
    deleted_by uuid,
    is_deleted boolean NOT NULL DEFAULT false,
    row_version bigint NOT NULL DEFAULT 1
);

CREATE TABLE workflows (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    mrv_id uuid NOT NULL REFERENCES mrvs(id),
    workflow_type varchar(80) NOT NULL DEFAULT 'MRV_DELIVERY',
    current_state varchar(80) NOT NULL,
    previous_state varchar(80),
    priority varchar(30) NOT NULL DEFAULT 'NORMAL' CHECK (priority IN ('LOW', 'NORMAL', 'HIGH', 'CRITICAL')),
    started_at timestamptz NOT NULL DEFAULT now(),
    completed_at timestamptz,
    failed_reason text,
    status_changed_at timestamptz NOT NULL DEFAULT now(),
    status_changed_by uuid,
    failure_reason text,
    retry_count integer NOT NULL DEFAULT 0,
    trace_id uuid,
    correlation_id uuid NOT NULL,
    request_id uuid,
    source_system varchar(100),
    source_reference_id varchar(150),
    created_at timestamptz NOT NULL DEFAULT now(),
    created_by uuid,
    updated_at timestamptz,
    updated_by uuid,
    deleted_at timestamptz,
    deleted_by uuid,
    is_deleted boolean NOT NULL DEFAULT false,
    row_version bigint NOT NULL DEFAULT 1
);

CREATE UNIQUE INDEX uq_workflows_active_mrv
ON workflows (mrv_id)
WHERE current_state NOT IN ('COMPLETED', 'FAILED', 'CANCELLED') AND is_deleted = false;

CREATE TABLE devices (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    device_code varchar(100) NOT NULL UNIQUE,
    device_type varchar(50) NOT NULL CHECK (device_type IN ('KARDEX', 'MOBILE_MANIPULATOR', 'SMARTBOX', 'AMR')),
    device_name varchar(150) NOT NULL,
    status varchar(50) NOT NULL DEFAULT 'OFFLINE',
    location varchar(150),
    last_heartbeat_at timestamptz,
    allowed_command_scope jsonb NOT NULL DEFAULT '[]'::jsonb,
    is_active boolean NOT NULL DEFAULT true,
    trace_id uuid,
    correlation_id uuid,
    request_id uuid,
    source_system varchar(100),
    source_reference_id varchar(150),
    created_at timestamptz NOT NULL DEFAULT now(),
    created_by uuid,
    updated_at timestamptz,
    updated_by uuid,
    deleted_at timestamptz,
    deleted_by uuid,
    is_deleted boolean NOT NULL DEFAULT false,
    row_version bigint NOT NULL DEFAULT 1
);

CREATE TABLE workflow_steps (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    workflow_id uuid NOT NULL REFERENCES workflows(id),
    step_name varchar(100) NOT NULL,
    state varchar(80) NOT NULL,
    assigned_device_id uuid REFERENCES devices(id),
    started_at timestamptz,
    completed_at timestamptz,
    previous_status varchar(80),
    status_changed_at timestamptz,
    status_changed_by uuid,
    failure_reason text,
    retry_count integer NOT NULL DEFAULT 0,
    trace_id uuid,
    correlation_id uuid,
    request_id uuid,
    source_system varchar(100),
    source_reference_id varchar(150),
    created_at timestamptz NOT NULL DEFAULT now(),
    created_by uuid,
    updated_at timestamptz,
    updated_by uuid,
    deleted_at timestamptz,
    deleted_by uuid,
    is_deleted boolean NOT NULL DEFAULT false,
    row_version bigint NOT NULL DEFAULT 1
);

CREATE TABLE smartboxes (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id uuid NOT NULL UNIQUE REFERENCES devices(id),
    smartbox_code varchar(100) NOT NULL UNIQUE,
    battery_pct integer CHECK (battery_pct BETWEEN 0 AND 100),
    connectivity_status varchar(50) NOT NULL DEFAULT 'OFFLINE',
    current_location varchar(150),
    operational_status varchar(50) NOT NULL DEFAULT 'OFFLINE',
    created_at timestamptz NOT NULL DEFAULT now(),
    created_by uuid,
    updated_at timestamptz,
    updated_by uuid,
    deleted_at timestamptz,
    deleted_by uuid,
    is_deleted boolean NOT NULL DEFAULT false,
    row_version bigint NOT NULL DEFAULT 1
);

CREATE TABLE smartbox_compartments (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    smartbox_id uuid NOT NULL REFERENCES smartboxes(id),
    door_id integer NOT NULL CHECK (door_id > 0),
    state varchar(80) NOT NULL DEFAULT 'AVAILABLE',
    occupied_flag boolean NOT NULL DEFAULT false,
    assigned_workflow_id uuid REFERENCES workflows(id),
    assigned_mrv_item_id uuid REFERENCES mrv_items(id),
    previous_status varchar(80),
    status_changed_at timestamptz,
    status_changed_by uuid,
    failure_reason text,
    retry_count integer NOT NULL DEFAULT 0,
    trace_id uuid,
    correlation_id uuid,
    request_id uuid,
    source_system varchar(100),
    source_reference_id varchar(150),
    created_at timestamptz NOT NULL DEFAULT now(),
    created_by uuid,
    updated_at timestamptz,
    updated_by uuid,
    deleted_at timestamptz,
    deleted_by uuid,
    is_deleted boolean NOT NULL DEFAULT false,
    row_version bigint NOT NULL DEFAULT 1,
    CONSTRAINT uq_smartbox_compartment_door UNIQUE (smartbox_id, door_id)
);

CREATE UNIQUE INDEX uq_smartbox_compartment_active_assignment
ON smartbox_compartments (smartbox_id, door_id)
WHERE assigned_workflow_id IS NOT NULL
  AND state IN ('RESERVED', 'LOADING', 'LOADED', 'DELIVERING', 'READY_FOR_COLLECTION', 'COLLECTION_IN_PROGRESS')
  AND is_deleted = false;

CREATE TABLE amrs (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id uuid NOT NULL UNIQUE REFERENCES devices(id),
    amr_code varchar(100) NOT NULL UNIQUE,
    battery_pct integer CHECK (battery_pct BETWEEN 0 AND 100),
    current_location jsonb,
    operational_status varchar(50) NOT NULL DEFAULT 'OFFLINE',
    created_at timestamptz NOT NULL DEFAULT now(),
    created_by uuid,
    updated_at timestamptz,
    updated_by uuid,
    deleted_at timestamptz,
    deleted_by uuid,
    is_deleted boolean NOT NULL DEFAULT false,
    row_version bigint NOT NULL DEFAULT 1
);

CREATE TABLE amr_missions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    workflow_id uuid NOT NULL REFERENCES workflows(id),
    amr_id uuid NOT NULL REFERENCES amrs(id),
    smartbox_id uuid NOT NULL REFERENCES smartboxes(id),
    mission_type varchar(50) NOT NULL CHECK (mission_type IN ('DELIVERY', 'RETURN_HOME', 'PICKUP')),
    mission_state varchar(80) NOT NULL,
    pickup_location varchar(150) NOT NULL,
    dropoff_location varchar(150) NOT NULL,
    started_at timestamptz,
    completed_at timestamptz,
    previous_status varchar(80),
    status_changed_at timestamptz,
    status_changed_by uuid,
    failure_reason text,
    retry_count integer NOT NULL DEFAULT 0,
    trace_id uuid,
    correlation_id uuid,
    request_id uuid,
    source_system varchar(100),
    source_reference_id varchar(150),
    created_at timestamptz NOT NULL DEFAULT now(),
    created_by uuid,
    updated_at timestamptz,
    updated_by uuid,
    deleted_at timestamptz,
    deleted_by uuid,
    is_deleted boolean NOT NULL DEFAULT false,
    row_version bigint NOT NULL DEFAULT 1
);

CREATE UNIQUE INDEX uq_amr_mission_active
ON amr_missions (workflow_id, smartbox_id, mission_type)
WHERE mission_state NOT IN ('COMPLETED', 'FAILED', 'CANCELLED') AND is_deleted = false;

CREATE TABLE robots (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id uuid NOT NULL UNIQUE REFERENCES devices(id),
    robot_code varchar(100) NOT NULL UNIQUE,
    operational_status varchar(50) NOT NULL DEFAULT 'OFFLINE',
    created_at timestamptz NOT NULL DEFAULT now(),
    created_by uuid,
    updated_at timestamptz,
    updated_by uuid,
    deleted_at timestamptz,
    deleted_by uuid,
    is_deleted boolean NOT NULL DEFAULT false,
    row_version bigint NOT NULL DEFAULT 1
);

CREATE TABLE robot_tasks (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    workflow_id uuid NOT NULL REFERENCES workflows(id),
    robot_id uuid NOT NULL REFERENCES robots(id),
    task_type varchar(50) NOT NULL DEFAULT 'PACKING',
    task_state varchar(80) NOT NULL,
    item_code varchar(100) NOT NULL,
    target_smartbox_id uuid REFERENCES smartboxes(id),
    target_compartment_id uuid REFERENCES smartbox_compartments(id),
    previous_status varchar(80),
    status_changed_at timestamptz,
    status_changed_by uuid,
    failure_reason text,
    retry_count integer NOT NULL DEFAULT 0,
    trace_id uuid,
    correlation_id uuid,
    request_id uuid,
    source_system varchar(100),
    source_reference_id varchar(150),
    created_at timestamptz NOT NULL DEFAULT now(),
    created_by uuid,
    updated_at timestamptz,
    updated_by uuid,
    deleted_at timestamptz,
    deleted_by uuid,
    is_deleted boolean NOT NULL DEFAULT false,
    row_version bigint NOT NULL DEFAULT 1
);

CREATE UNIQUE INDEX uq_robot_task_active
ON robot_tasks (robot_id)
WHERE task_state NOT IN ('COMPLETED', 'FAILED', 'CANCELLED') AND is_deleted = false;

CREATE TABLE telemetry_events (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id uuid NOT NULL REFERENCES devices(id),
    workflow_id uuid REFERENCES workflows(id),
    event_type varchar(100) NOT NULL,
    severity varchar(30) NOT NULL DEFAULT 'LOW' CHECK (severity IN ('CRITICAL', 'HIGH', 'MEDIUM', 'LOW')),
    occurred_at timestamptz NOT NULL,
    received_at timestamptz NOT NULL DEFAULT now(),
    sequence_no bigint,
    raw_payload jsonb NOT NULL,
    trace_id uuid,
    correlation_id uuid,
    request_id uuid,
    source_system varchar(100),
    source_reference_id varchar(150),
    created_at timestamptz NOT NULL DEFAULT now(),
    created_by uuid,
    updated_at timestamptz,
    updated_by uuid,
    deleted_at timestamptz,
    deleted_by uuid,
    is_deleted boolean NOT NULL DEFAULT false
);

CREATE UNIQUE INDEX uq_telemetry_event_dedupe_with_sequence
ON telemetry_events (device_id, event_type, occurred_at, sequence_no)
WHERE sequence_no IS NOT NULL;

CREATE INDEX ix_telemetry_event_dedupe_without_sequence
ON telemetry_events (device_id, event_type, occurred_at)
WHERE sequence_no IS NULL;

CREATE TABLE command_logs (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    workflow_id uuid REFERENCES workflows(id),
    device_id uuid NOT NULL REFERENCES devices(id),
    command_type varchar(100) NOT NULL,
    request_payload jsonb NOT NULL,
    response_payload jsonb,
    command_state varchar(50) NOT NULL DEFAULT 'CREATED',
    correlation_id uuid NOT NULL,
    trace_id uuid,
    request_id uuid,
    idempotency_key uuid NOT NULL,
    retry_count integer NOT NULL DEFAULT 0,
    last_attempt_at timestamptz,
    completed_at timestamptz,
    failure_reason text,
    created_at timestamptz NOT NULL DEFAULT now(),
    created_by uuid,
    updated_at timestamptz,
    updated_by uuid,
    deleted_at timestamptz,
    deleted_by uuid,
    is_deleted boolean NOT NULL DEFAULT false,
    row_version bigint NOT NULL DEFAULT 1,
    CONSTRAINT uq_command_device_idempotency UNIQUE (device_id, idempotency_key)
);

CREATE TABLE alerts (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    workflow_id uuid REFERENCES workflows(id),
    device_id uuid REFERENCES devices(id),
    severity varchar(30) NOT NULL CHECK (severity IN ('CRITICAL', 'HIGH', 'MEDIUM', 'LOW')),
    alert_type varchar(100) NOT NULL,
    message text NOT NULL,
    status varchar(50) NOT NULL DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'ACKNOWLEDGED', 'RESOLVED', 'DISMISSED')),
    acknowledged_by uuid REFERENCES user_accounts(id),
    acknowledged_at timestamptz,
    resolved_at timestamptz,
    trace_id uuid,
    correlation_id uuid,
    request_id uuid,
    source_system varchar(100),
    source_reference_id varchar(150),
    created_at timestamptz NOT NULL DEFAULT now(),
    created_by uuid,
    updated_at timestamptz,
    updated_by uuid,
    deleted_at timestamptz,
    deleted_by uuid,
    is_deleted boolean NOT NULL DEFAULT false,
    row_version bigint NOT NULL DEFAULT 1
);

CREATE TABLE audit_logs (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_type varchar(100) NOT NULL,
    entity_id varchar(100) NOT NULL,
    action varchar(100) NOT NULL,
    previous_value jsonb,
    new_value jsonb,
    actor_id uuid,
    actor_type varchar(30) NOT NULL CHECK (actor_type IN ('USER', 'SYSTEM', 'DEVICE')),
    actor_role varchar(80),
    source_ip inet,
    workflow_id uuid REFERENCES workflows(id),
    device_id uuid REFERENCES devices(id),
    mrv_id uuid REFERENCES mrvs(id),
    occurred_at timestamptz NOT NULL DEFAULT now(),
    correlation_id uuid NOT NULL,
    trace_id uuid,
    request_id uuid,
    source_system varchar(100),
    source_reference_id varchar(150),
    raw_payload jsonb
);

CREATE TABLE offline_queue (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    workflow_id uuid REFERENCES workflows(id),
    device_id uuid REFERENCES devices(id),
    operation_type varchar(100) NOT NULL,
    entity_type varchar(100) NOT NULL,
    entity_id uuid,
    payload jsonb NOT NULL,
    retry_count integer NOT NULL DEFAULT 0,
    queued_at timestamptz NOT NULL DEFAULT now(),
    last_attempt_at timestamptz,
    status varchar(50) NOT NULL DEFAULT 'QUEUED' CHECK (status IN ('QUEUED', 'BLOCKED', 'REPLAYED', 'FAILED', 'CANCELLED')),
    correlation_id uuid NOT NULL,
    idempotency_key uuid,
    created_at timestamptz NOT NULL DEFAULT now(),
    created_by uuid,
    updated_at timestamptz,
    updated_by uuid,
    deleted_at timestamptz,
    deleted_by uuid,
    is_deleted boolean NOT NULL DEFAULT false,
    row_version bigint NOT NULL DEFAULT 1
);

CREATE TABLE reconciliation_records (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id uuid NOT NULL REFERENCES devices(id),
    workflow_id uuid REFERENCES workflows(id),
    c2_state jsonb NOT NULL,
    device_state jsonb NOT NULL,
    resolution_action varchar(150),
    status varchar(50) NOT NULL DEFAULT 'RECONCILIATION_REQUIRED' CHECK (status IN ('RECONCILIATION_REQUIRED', 'RESOLVED', 'FAILED')),
    resolved_by uuid REFERENCES user_accounts(id),
    resolved_at timestamptz,
    correlation_id uuid NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    created_by uuid,
    updated_at timestamptz,
    updated_by uuid,
    deleted_at timestamptz,
    deleted_by uuid,
    is_deleted boolean NOT NULL DEFAULT false,
    row_version bigint NOT NULL DEFAULT 1
);

-- =========================================================
-- Indexes for operational queries, dashboards, audit, retry.
-- =========================================================

CREATE INDEX ix_mrv_status ON mrvs (status);
CREATE INDEX ix_mrv_request_datetime ON mrvs (request_datetime);
CREATE INDEX ix_mrv_correlation ON mrvs (correlation_id);
CREATE INDEX ix_mrv_items_mrv ON mrv_items (mrv_id);

CREATE INDEX ix_workflows_state ON workflows (current_state);
CREATE INDEX ix_workflows_mrv ON workflows (mrv_id);
CREATE INDEX ix_workflows_started ON workflows (started_at);
CREATE INDEX ix_workflows_correlation ON workflows (correlation_id);

CREATE INDEX ix_workflow_steps_workflow ON workflow_steps (workflow_id);
CREATE INDEX ix_workflow_steps_device ON workflow_steps (assigned_device_id);
CREATE INDEX ix_workflow_steps_state ON workflow_steps (state);

CREATE INDEX ix_devices_type_status ON devices (device_type, status);
CREATE INDEX ix_devices_last_heartbeat ON devices (last_heartbeat_at);

CREATE INDEX ix_smartbox_compartments_workflow ON smartbox_compartments (assigned_workflow_id);
CREATE INDEX ix_smartbox_compartments_item ON smartbox_compartments (assigned_mrv_item_id);

CREATE INDEX ix_amr_missions_workflow ON amr_missions (workflow_id);
CREATE INDEX ix_amr_missions_amr_state ON amr_missions (amr_id, mission_state);
CREATE INDEX ix_robot_tasks_workflow ON robot_tasks (workflow_id);
CREATE INDEX ix_robot_tasks_robot_state ON robot_tasks (robot_id, task_state);

CREATE INDEX ix_telemetry_device_time ON telemetry_events (device_id, occurred_at DESC);
CREATE INDEX ix_telemetry_workflow_time ON telemetry_events (workflow_id, occurred_at DESC);
CREATE INDEX ix_telemetry_type_severity ON telemetry_events (event_type, severity);

CREATE INDEX ix_command_workflow ON command_logs (workflow_id);
CREATE INDEX ix_command_device_state ON command_logs (device_id, command_state);
CREATE INDEX ix_command_correlation ON command_logs (correlation_id);
CREATE INDEX ix_command_created ON command_logs (created_at);

CREATE INDEX ix_alert_status_severity ON alerts (status, severity);
CREATE INDEX ix_alert_workflow ON alerts (workflow_id);
CREATE INDEX ix_alert_device ON alerts (device_id);

CREATE INDEX ix_audit_workflow_time ON audit_logs (workflow_id, occurred_at DESC);
CREATE INDEX ix_audit_mrv_time ON audit_logs (mrv_id, occurred_at DESC);
CREATE INDEX ix_audit_device_time ON audit_logs (device_id, occurred_at DESC);
CREATE INDEX ix_audit_actor_time ON audit_logs (actor_id, occurred_at DESC);
CREATE INDEX ix_audit_correlation ON audit_logs (correlation_id);
CREATE INDEX ix_audit_entity ON audit_logs (entity_type, entity_id);

CREATE INDEX ix_offline_queue_status ON offline_queue (status, queued_at);
CREATE INDEX ix_offline_queue_device ON offline_queue (device_id);
CREATE INDEX ix_reconciliation_status ON reconciliation_records (status, created_at);
CREATE INDEX ix_reconciliation_device ON reconciliation_records (device_id);

-- =========================================================
-- Audit immutability guards.
-- =========================================================

CREATE OR REPLACE FUNCTION prevent_audit_log_mutation()
RETURNS trigger AS $$
BEGIN
    RAISE EXCEPTION 'audit_logs are immutable and cannot be modified or deleted';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_prevent_audit_log_update
BEFORE UPDATE ON audit_logs
FOR EACH ROW EXECUTE FUNCTION prevent_audit_log_mutation();

CREATE TRIGGER trg_prevent_audit_log_delete
BEFORE DELETE ON audit_logs
FOR EACH ROW EXECUTE FUNCTION prevent_audit_log_mutation();

-- =========================================================
-- Generic row_version increment trigger.
-- Apply to mutable optimistic-concurrency tables.
-- =========================================================

CREATE OR REPLACE FUNCTION increment_row_version()
RETURNS trigger AS $$
BEGIN
    NEW.row_version := OLD.row_version + 1;
    NEW.updated_at := COALESCE(NEW.updated_at, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_user_accounts_row_version BEFORE UPDATE ON user_accounts FOR EACH ROW EXECUTE FUNCTION increment_row_version();
CREATE TRIGGER trg_mrvs_row_version BEFORE UPDATE ON mrvs FOR EACH ROW EXECUTE FUNCTION increment_row_version();
CREATE TRIGGER trg_mrv_items_row_version BEFORE UPDATE ON mrv_items FOR EACH ROW EXECUTE FUNCTION increment_row_version();
CREATE TRIGGER trg_workflows_row_version BEFORE UPDATE ON workflows FOR EACH ROW EXECUTE FUNCTION increment_row_version();
CREATE TRIGGER trg_workflow_steps_row_version BEFORE UPDATE ON workflow_steps FOR EACH ROW EXECUTE FUNCTION increment_row_version();
CREATE TRIGGER trg_devices_row_version BEFORE UPDATE ON devices FOR EACH ROW EXECUTE FUNCTION increment_row_version();
CREATE TRIGGER trg_smartboxes_row_version BEFORE UPDATE ON smartboxes FOR EACH ROW EXECUTE FUNCTION increment_row_version();
CREATE TRIGGER trg_smartbox_compartments_row_version BEFORE UPDATE ON smartbox_compartments FOR EACH ROW EXECUTE FUNCTION increment_row_version();
CREATE TRIGGER trg_amrs_row_version BEFORE UPDATE ON amrs FOR EACH ROW EXECUTE FUNCTION increment_row_version();
CREATE TRIGGER trg_amr_missions_row_version BEFORE UPDATE ON amr_missions FOR EACH ROW EXECUTE FUNCTION increment_row_version();
CREATE TRIGGER trg_robots_row_version BEFORE UPDATE ON robots FOR EACH ROW EXECUTE FUNCTION increment_row_version();
CREATE TRIGGER trg_robot_tasks_row_version BEFORE UPDATE ON robot_tasks FOR EACH ROW EXECUTE FUNCTION increment_row_version();
CREATE TRIGGER trg_command_logs_row_version BEFORE UPDATE ON command_logs FOR EACH ROW EXECUTE FUNCTION increment_row_version();
CREATE TRIGGER trg_alerts_row_version BEFORE UPDATE ON alerts FOR EACH ROW EXECUTE FUNCTION increment_row_version();
CREATE TRIGGER trg_offline_queue_row_version BEFORE UPDATE ON offline_queue FOR EACH ROW EXECUTE FUNCTION increment_row_version();
CREATE TRIGGER trg_reconciliation_records_row_version BEFORE UPDATE ON reconciliation_records FOR EACH ROW EXECUTE FUNCTION increment_row_version();

