# Development Sequence

Project: C2 Central Management System  
Date: 2026-05-28  
Role: Lead Software Architect  
Purpose: exact build order for backend, frontend, database, integrations, tests, and DevOps.

## Validation Command Notes

Commands below are the expected validation commands after each step is implemented. If the solution names differ, update the command in the same change that creates the solution/package.

| Area | Default Command |
| --- | --- |
| Backend build | `dotnet build backend/C2.sln` |
| Backend tests | `dotnet test backend/C2.sln` |
| Frontend build | `npm run build --prefix frontend` |
| Frontend tests | `npm test --prefix frontend -- --run` |
| Database migration | `dotnet ef database update --project backend/src/C2.Infrastructure --startup-project backend/src/C2.Api` |
| DevOps config | `docker compose -f infra/docker-compose.yml config` |

## Exact Build Order

| Step | Area | Objective | Input Files | Output Files | Dependencies | Validation Command |
| --- | --- | --- | --- | --- | --- | --- |
| 01 | DevOps | Create local development runtime for PostgreSQL and RabbitMQ. | `/specs/01-input-pack.md`, `/specs/09-security-nfr.md`, `/docs/architecture-decisions.md` | `/infra/docker-compose.yml`, `/infra/.env.example`, `/infra/README.md` | none | `docker compose -f infra/docker-compose.yml config` |
| 02 | Backend | Create .NET 8 Clean Architecture solution skeleton. | `/specs/11-agent-rules.md`, `/ai-rules/RULES.md`, `/ai-rules/BACKEND-RULES.md`, `/docs/architecture-decisions.md` | `/backend/C2.sln`, `/backend/src/C2.Api`, `/backend/src/C2.Application`, `/backend/src/C2.Domain`, `/backend/src/C2.Infrastructure`, `/backend/src/C2.Worker`, `/backend/tests/*` | 01 | `dotnet build backend/C2.sln` |
| 03 | Backend | Add API baseline: response envelope, exception middleware, correlation middleware, health checks. | `/specs/07-api-integration.md`, `/specs/09-security-nfr.md`, `/ai-rules/API-STANDARDS.md` | `/backend/src/C2.Api/Middleware/*`, `/backend/src/C2.Api/Controllers/HealthController.cs`, `/backend/src/C2.Application/Common/*` | 02 | `dotnet test backend/C2.sln --filter "Category=ApiBaseline"` |
| 04 | Database | Add EF Core PostgreSQL baseline and first migration. | `/specs/08-data-model.md`, `/ai-rules/BACKEND-RULES.md` | `/backend/src/C2.Infrastructure/Persistence/C2DbContext.cs`, `/backend/src/C2.Infrastructure/Persistence/Configurations/*`, `/backend/src/C2.Infrastructure/Migrations/*` | 02, 03 | `dotnet ef migrations list --project backend/src/C2.Infrastructure --startup-project backend/src/C2.Api` |
| 05 | Backend | Implement domain enums, value objects, core entities, and audit fields. | `/specs/04-domain-rules.md`, `/specs/08-data-model.md`, `/specs/11-agent-rules.md` | `/backend/src/C2.Domain/Entities/*`, `/backend/src/C2.Domain/Enums/*`, `/backend/src/C2.Domain/ValueObjects/*`, `/backend/src/C2.Domain/Common/*` | 04 | `dotnet test backend/C2.sln --filter "Category=Domain"` |
| 06 | Database | Add data constraints for duplicate MRV, compartment assignment, idempotency, row versioning, and event dedupe. | `/specs/08-data-model.md`, `/specs/07-api-integration.md` | `/backend/src/C2.Infrastructure/Persistence/Configurations/*`, `/backend/src/C2.Infrastructure/Migrations/*` | 05 | `dotnet test backend/C2.sln --filter "Category=Data"` |
| 07 | Backend | Implement workflow state machine and transition validation. | `/specs/04-domain-rules.md`, `/specs/05-workflows.md`, `/specs/11-agent-rules.md` | `/backend/src/C2.Domain/Workflow/*`, `/backend/src/C2.Application/Workflows/StateMachine/*` | 05, 06 | `dotnet test backend/C2.sln --filter "Category=WorkflowState"` |
| 08 | Backend | Implement immutable audit writer and command log service. | `/specs/04-domain-rules.md`, `/specs/08-data-model.md`, `/specs/09-security-nfr.md` | `/backend/src/C2.Application/Audit/*`, `/backend/src/C2.Application/Commands/CommandLogging/*`, `/backend/src/C2.Infrastructure/Audit/*` | 04, 05 | `dotnet test backend/C2.sln --filter "Category=Audit"` |
| 09 | Backend | Implement JWT authentication, refresh token support, RBAC policies, and security audit events. | `/specs/07-api-integration.md`, `/specs/09-security-nfr.md`, `/ai-rules/SECURITY-RULES.md` | `/backend/src/C2.Api/Auth/*`, `/backend/src/C2.Application/Identity/*`, `/backend/src/C2.Infrastructure/Identity/*` | 03, 04, 08 | `dotnet test backend/C2.sln --filter "Category=Security"` |
| 10 | Backend | Implement MRV ingestion command, validator, handler, API endpoint, duplicate rejection, and audit. | `/specs/03-prd.md`, `/specs/04-domain-rules.md`, `/specs/07-api-integration.md`, `/specs/10-acceptance-test.md` | `/backend/src/C2.Application/Mrvs/*`, `/backend/src/C2.Api/Controllers/MrvsController.cs`, `/backend/tests/C2.Application.Tests/Mrvs/*`, `/backend/tests/C2.Api.Tests/Mrvs/*` | 07, 08, 09 | `dotnet test backend/C2.sln --filter "Category=MRV"` |
| 11 | Backend | Implement workflow query and control APIs: get, retry, pause, resume, cancel. | `/specs/04-domain-rules.md`, `/specs/05-workflows.md`, `/specs/07-api-integration.md` | `/backend/src/C2.Application/Workflows/Commands/*`, `/backend/src/C2.Application/Workflows/Queries/*`, `/backend/src/C2.Api/Controllers/WorkflowsController.cs` | 07, 08, 09, 10 | `dotnet test backend/C2.sln --filter "Category=WorkflowApi"` |
| 12 | Backend | Implement device registry, device identity, heartbeat, status, and offline detection model. | `/specs/03-prd.md`, `/specs/04-domain-rules.md`, `/specs/08-data-model.md`, `/specs/09-security-nfr.md` | `/backend/src/C2.Application/Devices/*`, `/backend/src/C2.Api/Controllers/DevicesController.cs`, `/backend/src/C2.Worker/Heartbeat/*` | 08, 09 | `dotnet test backend/C2.sln --filter "Category=Devices"` |
| 13 | Integrations | Define vendor adapter interfaces and canonical DTOs. | `/specs/01-input-pack.md`, `/specs/07-api-integration.md`, `/specs/11-agent-rules.md` | `/backend/src/C2.Application/Integrations/Ab3/*`, `/Sap/*`, `/Kardex/*`, `/Robots/*`, `/SmartBoxes/*`, `/Amrs/*` | 10, 12 | `dotnet test backend/C2.sln --filter "Category=AdapterContracts"` |
| 14 | Integrations | Implement simulator adapters for AB3/UM, SAP, Kardex, Robot, SMARTBox, and AMR. | `/specs/05-workflows.md`, `/specs/07-api-integration.md`, `/specs/10-acceptance-test.md` | `/backend/src/C2.Infrastructure/Integrations/Simulators/*`, `/backend/tests/C2.Integration.Tests/Simulators/*` | 13 | `dotnet test backend/C2.sln --filter "Category=Simulators"` |
| 15 | Backend | Add RabbitMQ abstraction, command/event messages, retry metadata, DLQ contract, and worker host wiring. | `/specs/05-workflows.md`, `/specs/07-api-integration.md`, `/specs/09-security-nfr.md`, `/docs/architecture-decisions.md` | `/backend/src/C2.Application/Messaging/*`, `/backend/src/C2.Infrastructure/Messaging/*`, `/backend/src/C2.Worker/Program.cs` | 08, 13 | `dotnet test backend/C2.sln --filter "Category=Messaging"` |
| 16 | Integrations | Build SAP inventory validation and Kardex picking slice. | `/specs/04-domain-rules.md`, `/specs/05-workflows.md`, `/specs/07-api-integration.md`, `/specs/10-acceptance-test.md` | `/backend/src/C2.Application/Integrations/Sap/*`, `/backend/src/C2.Application/Integrations/Kardex/*`, `/backend/src/C2.Infrastructure/Integrations/Sap/*`, `/Kardex/*` | 10, 13, 15 | `dotnet test backend/C2.sln --filter "Category=KardexSap"` |
| 17 | Integrations | Build robot packing task dispatch and robot event ingestion. | `/specs/04-domain-rules.md`, `/specs/05-workflows.md`, `/specs/07-api-integration.md` | `/backend/src/C2.Application/Robots/*`, `/backend/src/C2.Api/Controllers/RobotsController.cs`, `/backend/src/C2.Infrastructure/Integrations/Robots/*` | 11, 12, 15, 16 | `dotnet test backend/C2.sln --filter "Category=Robot"` |
| 18 | Integrations | Build SMARTBox compartment assignment, door commands, event ingestion, and telemetry mapping. | `/specs/01-input-pack.md`, `/specs/04-domain-rules.md`, `/specs/05-workflows.md`, `/specs/07-api-integration.md`, `/specs/08-data-model.md` | `/backend/src/C2.Application/SmartBoxes/*`, `/backend/src/C2.Api/Controllers/SmartBoxesController.cs`, `/backend/src/C2.Infrastructure/Integrations/SmartBoxes/*` | 11, 12, 15, 17 | `dotnet test backend/C2.sln --filter "Category=SmartBox"` |
| 19 | Integrations | Build AMR mission dispatch, event ingestion, telemetry mapping, and return-home command. | `/specs/01-input-pack.md`, `/specs/04-domain-rules.md`, `/specs/05-workflows.md`, `/specs/07-api-integration.md` | `/backend/src/C2.Application/Amrs/*`, `/backend/src/C2.Api/Controllers/AmrsController.cs`, `/backend/src/C2.Infrastructure/Integrations/Amrs/*` | 11, 12, 15, 18 | `dotnet test backend/C2.sln --filter "Category=AMR"` |
| 20 | Backend | Implement recovery engine: retry policy, offline queue, reconciliation records, escalation alerts. | `/specs/04-domain-rules.md`, `/specs/05-workflows.md`, `/specs/07-api-integration.md`, `/specs/08-data-model.md`, `/specs/09-security-nfr.md` | `/backend/src/C2.Application/Recovery/*`, `/backend/src/C2.Application/Alerts/*`, `/backend/src/C2.Worker/Recovery/*`, `/backend/src/C2.Infrastructure/Recovery/*` | 15, 17, 18, 19 | `dotnet test backend/C2.sln --filter "Category=Recovery"` |
| 21 | Backend | Implement SignalR hubs and realtime event publisher for workflow, device, telemetry, alert, and audit updates. | `/specs/06-ux-behavior.md`, `/specs/07-api-integration.md`, `/specs/09-security-nfr.md` | `/backend/src/C2.Api/Hubs/*`, `/backend/src/C2.Application/Realtime/*`, `/backend/src/C2.Infrastructure/Realtime/*` | 09, 11, 12, 20 | `dotnet test backend/C2.sln --filter "Category=Realtime"` |
| 22 | Frontend | Create React TypeScript app shell, routing, layout, auth state, and RBAC route guards. | `/specs/06-ux-behavior.md`, `/specs/09-security-nfr.md`, `/ai-rules/FRONTEND-RULES.md` | `/frontend/package.json`, `/frontend/src/app/*`, `/frontend/src/routes/*`, `/frontend/src/features/auth/*` | 09 | `npm run build --prefix frontend && npm test --prefix frontend -- --run` |
| 23 | Frontend | Create typed API client, shared DTOs, response envelope handling, and error model. | `/specs/07-api-integration.md`, `/ai-rules/FRONTEND-RULES.md` | `/frontend/src/api/*`, `/frontend/src/types/*`, `/frontend/src/lib/queryClient.ts` | 22 | `npm test --prefix frontend -- --run api` |
| 24 | Frontend | Create SignalR realtime client, subscription hooks, reconnect handling, and stale/offline state handling. | `/specs/06-ux-behavior.md`, `/specs/07-api-integration.md` | `/frontend/src/realtime/*`, `/frontend/src/hooks/useRealtime*.ts` | 21, 22, 23 | `npm test --prefix frontend -- --run realtime` |
| 25 | Frontend | Build operations dashboard with active workflows, device status, AMR status, SMARTBox status, alerts, retry queue, and offline systems. | `/specs/03-prd.md`, `/specs/06-ux-behavior.md`, `/specs/10-acceptance-test.md` | `/frontend/src/features/dashboard/*`, `/frontend/src/features/alerts/*` | 23, 24 | `npm test --prefix frontend -- --run dashboard` |
| 26 | Frontend | Build workflow detail with MRV details, timeline, assigned devices, retry history, audit events, and manual actions. | `/specs/04-domain-rules.md`, `/specs/05-workflows.md`, `/specs/06-ux-behavior.md` | `/frontend/src/features/workflows/*` | 11, 23, 24, 25 | `npm test --prefix frontend -- --run workflows` |
| 27 | Frontend | Build SMARTBox monitoring view. | `/specs/01-input-pack.md`, `/specs/06-ux-behavior.md`, `/specs/07-api-integration.md` | `/frontend/src/features/smartboxes/*` | 18, 23, 24 | `npm test --prefix frontend -- --run smartboxes` |
| 28 | Frontend | Build AMR monitoring view. | `/specs/01-input-pack.md`, `/specs/06-ux-behavior.md`, `/specs/07-api-integration.md` | `/frontend/src/features/amrs/*` | 19, 23, 24 | `npm test --prefix frontend -- --run amrs` |
| 29 | Frontend | Build production collection flow with authentication, compartment display, confirmation, and success state. | `/specs/04-domain-rules.md`, `/specs/05-workflows.md`, `/specs/06-ux-behavior.md`, `/specs/10-acceptance-test.md` | `/frontend/src/features/collection/*` | 18, 21, 22, 23 | `npm test --prefix frontend -- --run collection` |
| 30 | Tests | Add backend unit tests for domain rules, validators, handlers, auth/RBAC, audit, and concurrency. | `/specs/04-domain-rules.md`, `/specs/08-data-model.md`, `/specs/09-security-nfr.md`, `/ai-rules/TESTING-RULES.md` | `/backend/tests/C2.Domain.Tests/*`, `/backend/tests/C2.Application.Tests/*`, `/backend/tests/C2.Api.Tests/*` | 05-21 | `dotnet test backend/C2.sln --filter "Category!=Integration"` |
| 31 | Tests | Add integration tests for API contracts, idempotency, RabbitMQ retry/DLQ, simulators, and recovery. | `/specs/07-api-integration.md`, `/specs/10-acceptance-test.md`, `/ai-rules/TESTING-RULES.md` | `/backend/tests/C2.Integration.Tests/*` | 14, 15, 20, 21 | `dotnet test backend/C2.sln --filter "Category=Integration"` |
| 32 | Tests | Add frontend tests for user-visible behavior, RBAC visibility, loading/error/empty/success states, and realtime updates. | `/specs/06-ux-behavior.md`, `/specs/10-acceptance-test.md`, `/ai-rules/TESTING-RULES.md` | `/frontend/src/**/*.test.tsx`, `/frontend/src/test/*` | 22-29 | `npm test --prefix frontend -- --run` |
| 33 | Tests | Add end-to-end happy path test from MRV to collection using simulators. | `/specs/05-workflows.md`, `/specs/10-acceptance-test.md` | `/tests/e2e/mrv-to-collection.spec.*`, `/tests/fixtures/mrv-valid.json` | 10-29, 31, 32 | `npm run test:e2e --prefix tests` |
| 34 | Tests | Add failure-path tests for robot failure, SMARTBox door failure, AMR mission failure, network/offline recovery, duplicate events, and invalid telemetry. | `/specs/04-domain-rules.md`, `/specs/05-workflows.md`, `/specs/10-acceptance-test.md` | `/tests/e2e/failure-paths.spec.*`, `/tests/fixtures/*` | 20, 31, 33 | `npm run test:e2e --prefix tests -- failure-paths` |
| 35 | DevOps | Add Dockerfiles for API, worker, and frontend. | `/docs/architecture-decisions.md`, `/docs/implementation-plan.md`, `/specs/09-security-nfr.md` | `/backend/src/C2.Api/Dockerfile`, `/backend/src/C2.Worker/Dockerfile`, `/frontend/Dockerfile` | 02, 15, 22 | `docker build -f backend/src/C2.Api/Dockerfile backend && docker build -f backend/src/C2.Worker/Dockerfile backend && docker build -f frontend/Dockerfile frontend` |
| 36 | DevOps | Add CI pipeline for restore, build, lint, test, Docker build, and artifact publishing. | `/ai-rules/TESTING-RULES.md`, `/ai-rules/REVIEW-RULES.md`, `/specs/09-security-nfr.md` | `/.github/workflows/ci.yml` or `/infra/pipelines/ci.yml` | 30, 31, 32, 35 | `dotnet test backend/C2.sln && npm test --prefix frontend -- --run && npm run build --prefix frontend` |
| 37 | DevOps | Add ECS Fargate deployment baseline: task definitions, services, ALB, logs, health checks, secrets references. | `/docs/architecture-decisions.md`, `/specs/09-security-nfr.md` | `/infra/aws/ecs/*`, `/infra/aws/README.md` | 35, 36 | `docker compose -f infra/docker-compose.yml config` |
| 38 | Tests | Run security, performance, and acceptance validation pack. | `/specs/09-security-nfr.md`, `/specs/10-acceptance-test.md`, `/ai-rules/REVIEW-RULES.md` | `/tests/reports/security.md`, `/tests/reports/performance.md`, `/tests/reports/acceptance.md` | 33, 34, 36, 37 | `dotnet test backend/C2.sln && npm test --prefix frontend -- --run && npm run test:e2e --prefix tests` |
| 39 | DevOps | Prepare release artifacts: smoke checklist, rollback plan, deployment checklist, environment matrix. | `/specs/10-acceptance-test.md`, `/docs/implementation-plan.md` | `/release/smoke-checklist.md`, `/release/rollback-plan.md`, `/release/deployment-checklist.md`, `/release/environment-matrix.md` | 38 | `Get-ChildItem release -File` |
| 40 | Tests | Execute final MVP readiness gate. | `/specs/10-acceptance-test.md`, `/release/*`, `/docs/development-sequence.md` | `/release/mvp-readiness-report.md` | 39 | `dotnet test backend/C2.sln && npm run build --prefix frontend && npm test --prefix frontend -- --run && npm run test:e2e --prefix tests` |

## Build Rules By Area

### Backend

1. Domain first: entities, state machine, validation rules.
2. Application second: CQRS commands/queries, validators, handlers.
3. Infrastructure third: EF Core, adapters, RabbitMQ, external services.
4. API last: thin controllers, policies, hubs, middleware.

### Frontend

1. App shell and auth.
2. Typed API client.
3. Realtime client.
4. Dashboard.
5. Workflow detail.
6. Device views.
7. Collection flow.
8. Tests and UX polish.

### Database

1. Core schema.
2. constraints and indexes.
3. audit/command/telemetry tables.
4. offline queue and reconciliation tables.
5. migration tests.

### Integrations

1. adapter interfaces.
2. simulator implementations.
3. SAP/Kardex.
4. Robot.
5. SMARTBox.
6. AMR.
7. recovery and reconciliation.

### Tests

1. unit tests with each backend/frontend slice.
2. integration tests after adapter and messaging layers.
3. E2E happy path after UI and simulators.
4. failure path tests after recovery.
5. security/performance/acceptance gates before release.

### DevOps

1. local compose first.
2. containers after buildable app exists.
3. CI after tests exist.
4. ECS baseline after containers.
5. release artifacts after validation pack.

## Do Not Start Before

| Work | Do Not Start Until |
| --- | --- |
| Vendor-specific integration implementation | adapter interfaces and simulator contracts exist |
| Realtime dashboard | SignalR backend events exist |
| E2E tests | simulators, API, frontend flow exist |
| ECS deployment | Dockerfiles and health checks exist |
| Release prep | acceptance, security, and failure-path validation pass |

