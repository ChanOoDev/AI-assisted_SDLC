# MVP Sprint Plan

Project: C2 Central Management System  
Role: Scrum Master and Technical Delivery Lead  
Planning basis: `/backlog/epics.md`, `/backlog/user-stories.md`, `/docs/development-sequence.md`

## Planning Assumptions

- Sprint length: 2 weeks.
- MVP target: working POC proving MRV-to-collection workflow with simulators or vendor sandboxes.
- Sprint demos must show integrated behavior, not only code completion.
- Critical path follows development sequence steps 01-40.
- Vendor APIs/hardware may be unstable, so simulators are mandatory before real integration.

## Sprint Overview

| Sprint | Theme | Main Outcome |
| --- | --- | --- |
| Sprint 0 | Foundation | Local platform, backend skeleton, DB baseline, API standards |
| Sprint 1 | Security, Domain, MRV | Workflow domain, audit, RBAC, MRV ingestion |
| Sprint 2 | Workflow + Adapter Contracts | workflow controls, device registry, adapter contracts, simulators |
| Sprint 3 | Picking + Robot + SMARTBox | SAP/Kardex, robot packing, SMARTBox load flow |
| Sprint 4 | AMR + Recovery + Realtime | AMR delivery, retry/recovery, SignalR events |
| Sprint 5 | Frontend Operations UX | app shell, dashboard, workflow detail, device views |
| Sprint 6 | Collection + E2E Hardening | collection flow, E2E happy path, failure paths |
| Sprint 7 | Release Readiness | DevOps, security/performance validation, MVP readiness |

## Sprint 0: Foundation

**Sprint Goal:** Establish the local and backend foundation required for all MVP delivery.

**Sprint Backlog:**

| Item | Source |
| --- | --- |
| Local PostgreSQL and RabbitMQ compose runtime | Development sequence step 01 |
| .NET 8 Clean Architecture solution skeleton | Step 02 |
| API response envelope, exception middleware, correlation middleware, health checks | Step 03 |
| EF Core PostgreSQL baseline and first migration | Step 04 |

**Dependencies:**

- Architecture decisions available.
- Development environment supports .NET 8, Docker, PostgreSQL, RabbitMQ.

**Risks:**

- Local environment setup inconsistency.
- Solution naming or folder structure drift from later commands.

**Demo Outcome:**

- Run local compose config.
- Build backend solution.
- Show health endpoint and standard response/error envelope.
- Show first migration recognized by EF Core.

**Exit Criteria:**

- `docker compose -f infra/docker-compose.yml config` passes.
- `dotnet build backend/C2.sln` passes.
- API baseline tests pass or are documented with blockers.
- No secrets committed.

## Sprint 1: Security, Domain, MRV

**Sprint Goal:** Create secure, auditable workflow creation from authoritative MRV input.

**Sprint Backlog:**

| Item | Source |
| --- | --- |
| Core entities, enums, value objects, audit fields | Step 05 |
| Data constraints for duplicate MRV, row versioning, idempotency basics | Step 06 |
| Workflow state machine and transition validation | Step 07 |
| Immutable audit writer and command log service | Step 08 |
| JWT authentication, refresh token, RBAC policies, security audit | Step 09 |
| US-001 Receive Valid MRV Payload | EPIC-01 |
| US-002 Reject Invalid MRV Payload | EPIC-01 |
| US-003 Prevent Duplicate Active MRV Workflow | EPIC-01 |
| US-020 Enforce Role-Based Access Control | EPIC-10 |
| US-021 Capture Immutable Audit Logs | EPIC-10 |

**Dependencies:**

- Sprint 0 complete.
- Role definitions confirmed: Admin, Supervisor, Warehouse Operator, Production User, Maintenance Engineer.

**Risks:**

- Audit immutability design too heavy for MVP.
- RBAC policy gaps create downstream rework.
- Duplicate MRV concurrency behavior missed.

**Demo Outcome:**

- Submit valid MRV and see workflow created.
- Submit invalid MRV and see validation rejection.
- Submit duplicate MRV and see duplicate rejection.
- Show audit record and RBAC-protected endpoint.

**Exit Criteria:**

- `dotnet test backend/C2.sln --filter "Category=Domain"` passes.
- `dotnet test backend/C2.sln --filter "Category=WorkflowState"` passes.
- `dotnet test backend/C2.sln --filter "Category=Security"` passes.
- `dotnet test backend/C2.sln --filter "Category=MRV"` passes.
- MRV audit and duplicate protection verified.

## Sprint 2: Workflow + Adapter Contracts

**Sprint Goal:** Make C2 able to control workflows and integrate safely through adapter contracts and simulators.

**Sprint Backlog:**

| Item | Source |
| --- | --- |
| Workflow query/control APIs: get, retry, pause, resume, cancel | Step 11 |
| Device registry, identity, heartbeat, offline detection model | Step 12 |
| Vendor adapter interfaces and canonical DTOs | Step 13 |
| Simulator adapters for AB3/UM, SAP, Kardex, Robot, SMARTBox, AMR | Step 14 |
| RabbitMQ abstraction, messages, retry metadata, DLQ contract, worker wiring | Step 15 |
| US-017 View Workflow Detail And Audit Timeline, backend API scope | EPIC-02, EPIC-08 |
| US-018 Retry Recoverable Device Command, platform skeleton | EPIC-09 |
| US-024 Monitor Device Health, backend scope | EPIC-08 |

**Dependencies:**

- Sprint 1 workflow, audit, auth foundations.
- Simulator behavior agreed for MVP demos.

**Risks:**

- Adapter contracts may diverge from vendor APIs.
- RabbitMQ retry model may be under-specified.
- Device heartbeat intervals may not be known yet.

**Demo Outcome:**

- Show workflow detail API.
- Pause/resume/retry/cancel workflow through protected APIs.
- Show registered devices and simulated heartbeat/offline status.
- Show a simulator emitting a device event.

**Exit Criteria:**

- `dotnet test backend/C2.sln --filter "Category=WorkflowApi"` passes.
- `dotnet test backend/C2.sln --filter "Category=Devices"` passes.
- `dotnet test backend/C2.sln --filter "Category=AdapterContracts"` passes.
- `dotnet test backend/C2.sln --filter "Category=Simulators"` passes.
- `dotnet test backend/C2.sln --filter "Category=Messaging"` passes.

## Sprint 3: Picking + Robot + SMARTBox

**Sprint Goal:** Complete warehouse-side preparation flow from validated MRV through SMARTBox loading.

**Sprint Backlog:**

| Item | Source |
| --- | --- |
| SAP inventory validation and Kardex picking slice | Step 16 |
| Robot packing task dispatch and event ingestion | Step 17 |
| SMARTBox compartment assignment, door commands, events, telemetry mapping | Step 18 |
| US-004 Validate Inventory Before Orchestration | EPIC-03 |
| US-005 Trigger Kardex Picking | EPIC-03 |
| US-006 Enforce Robot Handling Constraints | EPIC-04 |
| US-007 Dispatch Robot Packing Task | EPIC-04 |
| US-008 Handle Robot Packing Failure | EPIC-04 |
| US-009 Assign SMARTBox Compartment | EPIC-05 |
| US-010 Open And Close SMARTBox Door | EPIC-05 |
| US-011 Process SMARTBox Telemetry And Faults | EPIC-05 |
| US-022 Handle Emergency Stop Event, SMARTBox scope | EPIC-09 |

**Dependencies:**

- Sprint 2 adapter contracts, simulators, RabbitMQ.
- Robot item limits available from specs.
- SMARTBox door and event mapping confirmed or simulated.

**Risks:**

- SMARTBox retrofit/API instability.
- Robot eligibility validation missing item dimensions/weight from MRV payload.
- Treating command acknowledgement as physical completion.

**Demo Outcome:**

- Valid MRV passes SAP validation and triggers Kardex simulator.
- Robot simulator receives packing task and returns completion.
- SMARTBox simulator assigns compartment, opens/closes door, sends telemetry.
- Robot and SMARTBox fault paths trigger retry/escalation state.

**Exit Criteria:**

- `dotnet test backend/C2.sln --filter "Category=KardexSap"` passes.
- `dotnet test backend/C2.sln --filter "Category=Robot"` passes.
- `dotnet test backend/C2.sln --filter "Category=SmartBox"` passes.
- Command logs and audit records exist for robot and SMARTBox actions.
- Unsupported robot item path verified.

## Sprint 4: AMR + Recovery + Realtime

**Sprint Goal:** Complete delivery orchestration with AMR, resilient retry/recovery, and backend realtime event publishing.

**Sprint Backlog:**

| Item | Source |
| --- | --- |
| AMR mission dispatch, events, telemetry, return-home command | Step 19 |
| Recovery engine: retry policy, offline queue, reconciliation, escalation alerts | Step 20 |
| SignalR hubs and realtime event publisher | Step 21 |
| US-012 Dispatch AMR Delivery Mission | EPIC-06 |
| US-013 Process AMR Mission Completion | EPIC-06 |
| US-018 Retry Recoverable Device Command, full behavior | EPIC-09 |
| US-019 Reconcile Device State After Reconnect | EPIC-09 |
| US-022 Handle Emergency Stop Event, full behavior | EPIC-09 |
| US-024 Monitor Device Health, realtime/backend completion | EPIC-08 |

**Dependencies:**

- Sprint 3 SMARTBox ready-for-delivery state.
- RabbitMQ, device registry, alert/audit foundations.
- AMR simulator or sandbox available.

**Risks:**

- Recovery behavior could become overbuilt and delay demo.
- State reconciliation rules may be ambiguous when physical state conflicts with C2 state.
- Realtime events may publish before transaction/audit completion.

**Demo Outcome:**

- SMARTBox ready state dispatches AMR mission.
- AMR simulator completes mission and triggers return-home.
- Temporary offline event triggers retry/recovery.
- Reconnect triggers state reconciliation.
- SignalR emits workflow/device/alert updates.

**Exit Criteria:**

- `dotnet test backend/C2.sln --filter "Category=AMR"` passes.
- `dotnet test backend/C2.sln --filter "Category=Recovery"` passes.
- `dotnet test backend/C2.sln --filter "Category=Realtime"` passes.
- Retry attempts are audited.
- Reconciliation conflict raises alert and does not auto-replay unsafe commands.

## Sprint 5: Frontend Operations UX

**Sprint Goal:** Deliver the operator-facing UI for realtime monitoring, workflow visibility, and device status.

**Sprint Backlog:**

| Item | Source |
| --- | --- |
| React app shell, routing, auth state, RBAC route guards | Step 22 |
| Typed API client, DTOs, response envelope handling, error model | Step 23 |
| SignalR realtime client, hooks, reconnect/stale state | Step 24 |
| Operations dashboard | Step 25 |
| Workflow detail with timeline/audit/manual actions | Step 26 |
| SMARTBox monitoring view | Step 27 |
| AMR monitoring view | Step 28 |
| US-016 View Realtime Operations Dashboard | EPIC-08 |
| US-017 View Workflow Detail And Audit Timeline, UI scope | EPIC-08 |
| US-024 Monitor Device Health, UI scope | EPIC-08 |

**Dependencies:**

- Sprint 4 SignalR/backend APIs.
- Auth token flow available.
- Stable API DTOs.

**Risks:**

- UI may expose actions not enforced by backend RBAC.
- Realtime state can drift from React Query cache.
- Dashboard may become too dense for MVP operators.

**Demo Outcome:**

- Login as operator/supervisor.
- View realtime dashboard updating from simulator events.
- Drill into workflow detail and audit timeline.
- View SMARTBox and AMR status.
- Show offline/retry/alert visibility.

**Exit Criteria:**

- `npm run build --prefix frontend` passes.
- `npm test --prefix frontend -- --run dashboard` passes.
- `npm test --prefix frontend -- --run workflows` passes.
- `npm test --prefix frontend -- --run smartboxes` passes.
- `npm test --prefix frontend -- --run amrs` passes.
- RBAC visibility tested for critical actions.

## Sprint 6: Collection + E2E Hardening

**Sprint Goal:** Close the operational loop with production collection and validate the complete happy path plus key failures.

**Sprint Backlog:**

| Item | Source |
| --- | --- |
| Production collection flow UI | Step 29 |
| Backend unit tests for domain, validators, handlers, auth/RBAC, audit, concurrency | Step 30 |
| Integration tests for API contracts, idempotency, RabbitMQ, simulators, recovery | Step 31 |
| Frontend tests for behavior, RBAC, loading/error/empty/success, realtime | Step 32 |
| E2E happy path from MRV to collection | Step 33 |
| Failure-path tests for robot, SMARTBox, AMR, network/offline recovery | Step 34 |
| US-014 Notify Production User For Collection | EPIC-07 |
| US-015 Authenticate And Confirm Collection | EPIC-07 |
| US-023 Detect Collection Timeout | EPIC-09 |
| US-025 Validate End-To-End MVP Workflow | All critical epics |

**Dependencies:**

- Sprints 1-5 complete.
- Simulators stable.
- Test fixtures available for valid MRV and failure paths.

**Risks:**

- E2E tests may be flaky if asynchronous events lack deterministic test hooks.
- Collection GI label scan behavior may need clarification.
- Timeout thresholds may not be confirmed.

**Demo Outcome:**

- Run full MRV-to-collection happy path in UI.
- Production user authenticates and confirms collection.
- Dashboard shows workflow completed.
- Demonstrate one failure path: SMARTBox offline or AMR mission failure with retry/escalation.

**Exit Criteria:**

- `npm test --prefix frontend -- --run collection` passes.
- `dotnet test backend/C2.sln --filter "Category!=Integration"` passes.
- `dotnet test backend/C2.sln --filter "Category=Integration"` passes.
- `npm run test:e2e --prefix tests` passes or blocker documented.
- AC-001 through AC-009 mapped to tests.

## Sprint 7: Release Readiness

**Sprint Goal:** Prepare the MVP for deployable, supportable, reviewable delivery.

**Sprint Backlog:**

| Item | Source |
| --- | --- |
| Dockerfiles for API, worker, frontend | Step 35 |
| CI pipeline for restore, build, lint, test, Docker build, artifact publishing | Step 36 |
| ECS Fargate deployment baseline | Step 37 |
| Security, performance, acceptance validation pack | Step 38 |
| Release artifacts: smoke checklist, rollback plan, deployment checklist, environment matrix | Step 39 |
| Final MVP readiness gate and report | Step 40 |

**Dependencies:**

- Sprint 6 tests and E2E validation.
- Environment configuration values and secret-management approach.
- Deployment target/network assumptions confirmed enough for MVP.

**Risks:**

- AWS/network access may not be available for full deployment validation.
- Performance gaps may appear late under telemetry load.
- Missing vendor sandbox/hardware could limit final UAT confidence.

**Demo Outcome:**

- Show CI pipeline execution or local equivalent.
- Build container images.
- Present smoke checklist, rollback plan, deployment checklist, and MVP readiness report.
- Show acceptance, security, and performance validation results.

**Exit Criteria:**

- Docker builds for API, worker, and frontend pass.
- CI command set passes locally or in pipeline.
- `dotnet test backend/C2.sln && npm run build --prefix frontend && npm test --prefix frontend -- --run && npm run test:e2e --prefix tests` passes or has approved release exception.
- Release artifacts exist in `/release`.
- No critical defects open.
- Product owner accepts MVP demo scope.

## Cross-Sprint Dependency Map

| Dependency | Needed By | Owner |
| --- | --- | --- |
| PostgreSQL/RabbitMQ local runtime | All backend/integration sprints | Tech Lead |
| Workflow state model | MRV, integrations, recovery, dashboard | Backend Lead |
| Audit and command logging | All critical actions | Backend Lead |
| JWT/RBAC | APIs, frontend route guards, collection | Backend + Frontend Leads |
| Adapter contracts/simulators | Integration and E2E validation | Integration Lead |
| SignalR event stream | Dashboard and realtime UX | Backend Lead |
| Stable API DTOs | Frontend and E2E tests | Backend + Frontend Leads |
| Test fixtures | Integration, E2E, demo | QA Lead |
| Docker/CI baseline | Release readiness | DevOps Lead |

## Program Risks

| Risk | Likelihood | Impact | Mitigation |
| --- | --- | --- | --- |
| Vendor API instability | High | High | Build simulators first; keep adapters isolated; contract-test vendor mappings |
| SMARTBox hardware delay | High | High | Demo through simulator; schedule early field integration once hardware available |
| Realtime/network instability | Medium | High | Heartbeats, offline status, retry queue, reconciliation, dashboard stale indicators |
| Workflow race conditions | Medium | High | Optimistic concurrency, idempotency keys, duplicate event detection |
| Security/RBAC gaps | Medium | High | Security tests every sprint after Sprint 1; backend authorization mandatory |
| E2E test flakiness | Medium | Medium | Deterministic simulator hooks; avoid timing-only assertions |
| Scope pressure | High | Medium | Keep MVP non-goals out: AI optimization, advanced analytics, multi-site support |
| Deployment environment uncertainty | Medium | Medium | Local compose first; ECS baseline with explicit environment matrix |

## MVP Release Exit Criteria

- All critical stories US-001 through US-022 and US-025 are complete or have approved exception.
- High priority stories US-017, US-023, and US-024 are complete or deferred with product owner approval.
- AC-001 through AC-009 pass.
- End-to-end MRV-to-collection demo succeeds with simulator or vendor sandbox.
- Retry/recovery validated for at least robot failure, SMARTBox offline/door failure, AMR mission failure, and network disconnect.
- Dashboard updates realtime with workflow, device, alert, retry, and offline states.
- JWT/RBAC and audit logging validated.
- No critical defects open.
- Release checklist, rollback plan, smoke checklist, and MVP readiness report are complete.

