# Frontend Tasks

Project: C2 Central Management System  
Role: Senior React Frontend Architect  
Inputs:

- `/specs/06-ux-behavior.md`
- `/specs/07-api-integration.md`
- `/openapi/c2-api.yaml`
- `/openapi/websocket-events.md`
- `/ai-rules/FRONTEND-RULES.md`

## Frontend Principles

- Use React + TypeScript strict mode + Vite.
- Use React Query for server state.
- Use feature-based structure.
- Do not put business logic in components.
- Use typed API models from OpenAPI.
- Protect routes by RBAC, but keep backend authorization mandatory.
- Handle loading, error, empty, success, stale, offline, and reconnect states.
- Realtime updates are default for operational screens.
- Disable invalid operations when subsystem is offline, workflow locked, user lacks permission, or workflow state is invalid.

## Proposed Structure

```text
frontend/
  src/
    app/
    api/
    components/
    features/
      alerts/
      amrs/
      auth/
      dashboard/
      smartboxes/
      workflows/
    hooks/
    lib/
    realtime/
    routes/
    test/
    types/
```

## Task List

### FE-001 Vite Project Setup

**Objective:** Create the React TypeScript application foundation.

**Scope:**

- Initialize Vite React TypeScript app.
- Enable TypeScript strict mode.
- Add React Query, React Router, SignalR client, test stack, lint/format scripts.
- Add environment config for API base URL and WebSocket base URL.

**Output Files:**

- `/frontend/package.json`
- `/frontend/vite.config.ts`
- `/frontend/tsconfig.json`
- `/frontend/src/app/*`
- `/frontend/src/main.tsx`

**Dependencies:** none

**Validation:** `npm run build --prefix frontend`

### FE-002 App Shell And Layout

**Objective:** Build the operational portal shell.

**Scope:**

- App root providers.
- React Query client.
- Global error boundary.
- Base layout for dashboard/detail views.
- Shared status colors for Running, Warning, Fault, Offline, Emergency.

**Output Files:**

- `/frontend/src/app/App.tsx`
- `/frontend/src/app/providers.tsx`
- `/frontend/src/components/layout/*`
- `/frontend/src/components/status/*`

**Dependencies:** FE-001

**Validation:** `npm run build --prefix frontend`

### FE-003 Routing

**Objective:** Define protected MVP routes.

**Scope:**

- `/login`
- `/`
- `/dashboard`
- `/workflows/:workflowId`
- `/smartboxes`
- `/smartboxes/:smartBoxId`
- `/amrs`
- `/amrs/:amrId`
- `/collection`
- `/alerts`

**Output Files:**

- `/frontend/src/routes/router.tsx`
- `/frontend/src/routes/ProtectedRoute.tsx`
- `/frontend/src/routes/roleRoutes.ts`

**Dependencies:** FE-002, FE-004

**Validation:** `npm test --prefix frontend -- --run routes`

### FE-004 Auth Flow

**Objective:** Implement JWT login, refresh, logout, user role state, and route protection.

**Scope:**

- Use `/api/auth/login`, `/api/auth/refresh`, `/api/auth/logout`.
- Store token safely according to project decision.
- Decode or load user role.
- Enforce RBAC route visibility for Admin, Supervisor, Warehouse Operator, Production User, Maintenance Engineer.
- Handle invalid token, expired session, and forced logout.

**Output Files:**

- `/frontend/src/features/auth/*`
- `/frontend/src/api/authApi.ts`
- `/frontend/src/hooks/useAuth.ts`
- `/frontend/src/types/auth.ts`

**Dependencies:** FE-001, FE-010

**Validation:** `npm test --prefix frontend -- --run auth`

### FE-005 API Type Generation

**Objective:** Generate or manually define typed API DTOs from `/openapi/c2-api.yaml`.

**Scope:**

- Standard response envelope.
- Error response schema.
- Auth DTOs.
- MRV DTOs.
- Workflow DTOs.
- SMARTBox DTOs.
- AMR DTOs.
- Robot DTOs.
- Audit DTOs.
- Shared `WorkflowState`, `DeviceStatus`, severity, role enums.

**Output Files:**

- `/frontend/src/types/api.ts`
- `/frontend/src/types/enums.ts`
- `/frontend/src/api/generated/*` if using generator

**Dependencies:** FE-001

**Validation:** `npm run typecheck --prefix frontend`

### FE-006 API Client

**Objective:** Build a typed API client around the standard envelope.

**Scope:**

- Add `X-Correlation-Id` and `X-Request-Id`.
- Add `Idempotency-Key` for command APIs.
- Attach bearer token.
- Normalize standard envelope success/error.
- Convert raw API errors into user-safe UI errors.
- Support pagination parameters.

**Endpoint Groups:**

- Auth: `/api/auth/*`
- MRVs: `/api/mrvs`
- Workflows: `/api/workflows/*`
- SMARTBoxes: `/api/smartboxes/*`
- AMRs: `/api/amrs/*`
- Robots: `/api/robots/*`
- Audit: `/api/audit`

**Output Files:**

- `/frontend/src/api/httpClient.ts`
- `/frontend/src/api/errors.ts`
- `/frontend/src/api/idempotency.ts`
- `/frontend/src/api/workflowsApi.ts`
- `/frontend/src/api/smartboxesApi.ts`
- `/frontend/src/api/amrsApi.ts`
- `/frontend/src/api/robotsApi.ts`
- `/frontend/src/api/auditApi.ts`

**Dependencies:** FE-005

**Validation:** `npm test --prefix frontend -- --run api`

### FE-007 React Query Hooks

**Objective:** Expose API data through reusable query/mutation hooks.

**Scope:**

- Workflow search/detail hooks.
- Workflow action mutations: retry, pause, resume, cancel.
- SMARTBox list/status and door commands.
- AMR list and mission command if exposed to UI.
- Robot status hooks.
- Audit search hooks.
- Auth mutations.
- Optimistic updates only where safe; otherwise refetch on realtime event.

**Output Files:**

- `/frontend/src/features/workflows/queries.ts`
- `/frontend/src/features/smartboxes/queries.ts`
- `/frontend/src/features/amrs/queries.ts`
- `/frontend/src/features/alerts/queries.ts`
- `/frontend/src/features/auth/queries.ts`

**Dependencies:** FE-006

**Validation:** `npm test --prefix frontend -- --run queries`

### FE-008 Realtime Client

**Objective:** Implement SignalR/WebSocket integration from `/openapi/websocket-events.md`.

**Scope:**

- Connect to `/ws/operations`.
- Subscribe to `/ws/workflows/{workflowId}`.
- Subscribe to `/ws/devices/{deviceId}/telemetry`.
- Handle reconnect and stale state.
- Deduplicate by `eventId` or `deviceId + eventType + occurredAt + sequenceNo`.
- Invalidate React Query caches on critical events.

**Events:**

- `workflow.updated`
- `workflow.retry.updated`
- `workflow.reconciliation.required`
- `device.status.updated`
- `device.heartbeat.received`
- `smartbox.door.updated`
- `smartbox.compartment.updated`
- `smartbox.battery.alert`
- `amr.mission.updated`
- `amr.location.updated`
- `robot.task.updated`
- `robot.health.updated`
- `alert.created`
- `alert.acknowledged`
- `delivery.updated`
- `audit.record.created`

**Output Files:**

- `/frontend/src/realtime/client.ts`
- `/frontend/src/realtime/events.ts`
- `/frontend/src/realtime/useOperationsStream.ts`
- `/frontend/src/realtime/useWorkflowStream.ts`
- `/frontend/src/realtime/useDeviceTelemetryStream.ts`

**Dependencies:** FE-004, FE-006, FE-007

**Validation:** `npm test --prefix frontend -- --run realtime`

### FE-009 Dashboard

**Objective:** Build the realtime operations dashboard.

**Scope:**

- Active workflows.
- Robot fleet status.
- SMARTBox fleet status.
- AMR mission status.
- Alerts panel.
- Delivery queue.
- Offline systems.
- Retry queue.
- Filters by workflow, device, and status.
- Click-through to workflow/device detail.

**UX Requirements:**

- No manual refresh required.
- Fault and emergency states immediately visible.
- Keep screen operational, scannable, and low-clutter.

**Output Files:**

- `/frontend/src/features/dashboard/DashboardPage.tsx`
- `/frontend/src/features/dashboard/components/*`
- `/frontend/src/features/dashboard/hooks.ts`

**Dependencies:** FE-007, FE-008, FE-012

**Validation:** `npm test --prefix frontend -- --run dashboard`

### FE-010 Workflow Detail

**Objective:** Build workflow drilldown and operational timeline.

**Scope:**

- MRV details.
- Current workflow state.
- Next action/blocking reason.
- Assigned devices.
- Retry history.
- Escalation visibility.
- Audit events.
- Manual actions based on RBAC and valid workflow state.

**Actions:**

- Retry workflow.
- Pause workflow.
- Resume workflow.
- Cancel workflow.

**Output Files:**

- `/frontend/src/features/workflows/WorkflowDetailPage.tsx`
- `/frontend/src/features/workflows/components/*`
- `/frontend/src/features/workflows/actions.ts`

**Dependencies:** FE-007, FE-008, FE-011, FE-012

**Validation:** `npm test --prefix frontend -- --run workflows`

### FE-011 Critical Action Confirmation

**Objective:** Create reusable confirmation UX for dangerous actions.

**Scope:**

- Manual override.
- Retry after critical fault.
- Cancel workflow.
- Force door open/close.
- Emergency recovery acknowledgement.

**Output Files:**

- `/frontend/src/components/confirm/CriticalActionDialog.tsx`
- `/frontend/src/hooks/useCriticalAction.ts`

**Dependencies:** FE-002, FE-004

**Validation:** `npm test --prefix frontend -- --run critical-action`

### FE-012 Validation UX

**Objective:** Centralize validation and user-safe error behavior.

**Scope:**

- Form validation helpers.
- API validation error rendering.
- Contextual operational error messages.
- Disabled action rules.
- Blocked workflow reason display.
- Retry ETA/retry count display components.

**Output Files:**

- `/frontend/src/lib/validation.ts`
- `/frontend/src/components/errors/*`
- `/frontend/src/components/blocked-state/*`
- `/frontend/src/components/retry/*`

**Dependencies:** FE-006

**Validation:** `npm test --prefix frontend -- --run validation`

### FE-013 SMARTBox View

**Objective:** Build SMARTBox monitoring and compartment status view.

**Scope:**

- SMARTBox online/offline status.
- Battery level.
- Door status.
- Compartment occupancy.
- Connectivity state.
- Fault and emergency events.
- Door open/close animation state.
- Disable unsafe door actions when offline, emergency stopped, invalid door, or forbidden by RBAC.

**Output Files:**

- `/frontend/src/features/smartboxes/SmartBoxListPage.tsx`
- `/frontend/src/features/smartboxes/SmartBoxDetailPage.tsx`
- `/frontend/src/features/smartboxes/components/*`

**Dependencies:** FE-007, FE-008, FE-011, FE-012

**Validation:** `npm test --prefix frontend -- --run smartboxes`

### FE-014 AMR View

**Objective:** Build AMR monitoring screen.

**Scope:**

- AMR mission state.
- Current location.
- Battery level.
- Autonomous status.
- Safety alerts.
- Mission queue.
- Mission progress tracking.
- Fault indicators.

**Output Files:**

- `/frontend/src/features/amrs/AmrListPage.tsx`
- `/frontend/src/features/amrs/AmrDetailPage.tsx`
- `/frontend/src/features/amrs/components/*`

**Dependencies:** FE-007, FE-008, FE-012

**Validation:** `npm test --prefix frontend -- --run amrs`

### FE-015 Alert Panel

**Objective:** Build reusable alert visibility and acknowledgement UI.

**Scope:**

- Critical, High, Medium, Low severity treatment.
- Sticky/flashing critical alert state.
- Persistent high alerts.
- Standard medium and feed-style low alerts.
- Acknowledge alert action.
- Show escalation owner, level, and pending action when available.

**Output Files:**

- `/frontend/src/features/alerts/AlertPanel.tsx`
- `/frontend/src/features/alerts/AlertListPage.tsx`
- `/frontend/src/features/alerts/components/*`

**Dependencies:** FE-007, FE-008, FE-011, FE-012

**Validation:** `npm test --prefix frontend -- --run alerts`

### FE-016 Production Collection Flow

**Objective:** Build simplified collection experience for production users.

**Scope:**

- Assigned SMARTBox.
- Compartment number.
- Delivery ETA/status.
- User authentication state.
- Confirm collection.
- GI label scan placeholder or integration hook.
- Success confirmation.
- User-friendly blocked states for unauthorized or unavailable collection.

**Output Files:**

- `/frontend/src/features/collection/CollectionPage.tsx`
- `/frontend/src/features/collection/components/*`

**Dependencies:** FE-004, FE-007, FE-012, FE-013

**Validation:** `npm test --prefix frontend -- --run collection`

### FE-017 Shared Status And Telemetry Components

**Objective:** Standardize operational visual language.

**Scope:**

- Status badge.
- Battery indicator.
- Offline indicator.
- Last connected timestamp.
- Retry indicator.
- Fault indicator.
- Emergency banner.
- Timeline item.

**Output Files:**

- `/frontend/src/components/status/*`
- `/frontend/src/components/telemetry/*`
- `/frontend/src/components/timeline/*`

**Dependencies:** FE-002

**Validation:** `npm test --prefix frontend -- --run components`

### FE-018 Empty, Loading, Error, Stale States

**Objective:** Ensure every feature surface handles non-happy states.

**Scope:**

- Dashboard empty state.
- Workflow not found.
- No devices registered.
- No active alerts.
- API unavailable.
- WebSocket disconnected.
- Stale cached data marker.

**Output Files:**

- `/frontend/src/components/states/*`
- feature-level state usage updates

**Dependencies:** FE-009, FE-010, FE-013, FE-014, FE-015

**Validation:** `npm test --prefix frontend -- --run states`

### FE-019 Frontend Unit And Component Tests

**Objective:** Cover feature behavior without brittle implementation-detail tests.

**Scope:**

- Auth flow tests.
- RBAC visibility tests.
- API client envelope/error tests.
- Realtime event handling tests.
- Dashboard state rendering tests.
- Workflow action availability tests.
- SMARTBox/AMR/alert rendering tests.

**Output Files:**

- `/frontend/src/**/*.test.ts`
- `/frontend/src/**/*.test.tsx`
- `/frontend/src/test/*`

**Dependencies:** FE-004 through FE-018

**Validation:** `npm test --prefix frontend -- --run`

### FE-020 Integration Test Fixtures And Mocks

**Objective:** Provide deterministic frontend testing against API and WebSocket behavior.

**Scope:**

- Mock standard success envelope.
- Mock error envelope.
- Mock workflows.
- Mock SMARTBoxes.
- Mock AMRs.
- Mock alerts.
- Mock WebSocket event envelopes.
- Simulate reconnect and duplicate events.

**Output Files:**

- `/frontend/src/test/fixtures/*`
- `/frontend/src/test/msw/*`
- `/frontend/src/test/realtime/*`

**Dependencies:** FE-005, FE-006, FE-008

**Validation:** `npm test --prefix frontend -- --run fixtures`

### FE-021 Accessibility And Operator Ergonomics Pass

**Objective:** Make operational UI usable under pressure.

**Scope:**

- Keyboard navigation for primary workflows.
- Focus management for critical alerts and confirmations.
- Color plus text/icon status indicators.
- Button labels and disabled reasons.
- No overlapping text in compact dashboard panels.

**Output Files:**

- updates across `/frontend/src/components/*`
- updates across `/frontend/src/features/*`

**Dependencies:** FE-009 through FE-018

**Validation:** `npm test --prefix frontend -- --run accessibility`

### FE-022 Build And Quality Gate

**Objective:** Establish frontend done criteria.

**Scope:**

- Typecheck.
- Unit/component tests.
- Production build.
- Verify no direct fetch in components.
- Verify no `any` unless justified.
- Verify protected routes.
- Verify loading/error/empty/success states.

**Output Files:**

- `/frontend/README.md`
- `/frontend/src/test/quality-checklist.md`

**Dependencies:** all frontend tasks

**Validation:** `npm run build --prefix frontend && npm test --prefix frontend -- --run`

## Implementation Order

1. FE-001 Vite Project Setup
2. FE-002 App Shell And Layout
3. FE-005 API Type Generation
4. FE-006 API Client
5. FE-004 Auth Flow
6. FE-003 Routing
7. FE-007 React Query Hooks
8. FE-008 Realtime Client
9. FE-017 Shared Status And Telemetry Components
10. FE-012 Validation UX
11. FE-011 Critical Action Confirmation
12. FE-009 Dashboard
13. FE-010 Workflow Detail
14. FE-013 SMARTBox View
15. FE-014 AMR View
16. FE-015 Alert Panel
17. FE-016 Production Collection Flow
18. FE-018 Empty, Loading, Error, Stale States
19. FE-020 Integration Test Fixtures And Mocks
20. FE-019 Frontend Unit And Component Tests
21. FE-021 Accessibility And Operator Ergonomics Pass
22. FE-022 Build And Quality Gate

## Done Criteria

- TypeScript strict mode passes.
- No direct `fetch` calls inside components.
- API calls go through typed client and React Query hooks.
- RBAC hides unavailable actions; backend authorization remains assumed mandatory.
- Critical actions require confirmation.
- Realtime updates refresh dashboard and detail views.
- Stale/offline/reconnect states are visible.
- Every feature handles loading, error, empty, and success states.
- Tests cover visible behavior, validation, RBAC visibility, API failure, and realtime update handling.

