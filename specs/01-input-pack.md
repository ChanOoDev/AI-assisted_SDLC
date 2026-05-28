# PROJECT INPUT PACK — C2 CENTRAL MANAGEMENT SYSTEM

## PROJECT OVERVIEW

### Project

C2 Central Management System (Warehouse Automation Orchestration Platform)

### Objective

Develop centralized orchestration platform for:

- MRV workflow
- warehouse automation
- robot coordination
- SMARTBox operations
- AMR delivery
- realtime monitoring
- audit tracking

### Integrated Systems

- AB3 / Ultramain (UM)
- SAP
- Kardex ASRS/PPS
- Mobile Manipulator
- SMARTBox
- OTSAW AMR + FMCS

### MVP Target

POC/MVP delivery target: June 2026.

### Key Business Goals

- manpower reduction
- realtime visibility
- end-to-end traceability
- automated delivery workflow
- centralized monitoring
- scalable automation platform

---

# BUSINESS PROBLEMS

## No Unified Communication Protocol

No centralized communication/orchestration layer exists between:

- AB3/UM
- Kardex
- Mobile Manipulator
- SMARTBox
- OTSAW AMR

Impact:

- disconnected workflows
- manual coordination
- operational delays

---

## Poor Material Traceability

Current process lacks:

- realtime tracking
- audit trail
- accountability
- movement visibility

Impact:

- lost materials
- weak operational visibility
- poor analytics capability

---

## Heavy Manual Dependency

Current workflows require:

- manual monitoring
- manual coordination
- manual delivery handling

Impact:

- higher manpower cost
- operational inefficiency
- increased waiting time

---

## Limited Operational Visibility

No centralized dashboard exists for:

- robot health
- mission status
- delivery tracking
- compartment status
- workflow monitoring

---

# CONFIRMED REQUIREMENTS

## MRV Workflow

System shall:

- receive MRV JSON payload
- create workflow automatically
- orchestrate downstream automation

---

## Kardex Integration

C2 shall:

- receive MRV
- trigger Kardex actions
- coordinate picking workflow

---

## Mobile Manipulator Integration

C2 shall:

- trigger packing workflow
- receive packing completion
- receive robot health
- receive robot alerts

Robot scope:

- single-label items only
- max size: 25x25x5 cm
- max weight: 1–2 kg

---

## SMARTBox Integration

C2 shall:

- assign compartments
- open/close doors
- monitor battery
- receive heartbeat/fault events
- monitor occupancy

Supported commands:

- cmd_open_door
- cmd_close_door
- cmd_query_status

Supported events:

- evt_heartbeat
- evt_door_opened
- evt_door_closed
- evt_battery_alert
- evt_fault
- evt_emergency_stop
- evt_boot

---

## OTSAW AMR Integration

C2 shall:

- assign delivery missions
- trigger pickup/delivery
- monitor battery/GPS
- receive mission status
- trigger return-home workflow

Environment:

- up to 6 SmartBoxes at warehouse
- up to 6 SmartBoxes at hangar
- 3 AMRs operating concurrently

---

## Web Application

Web app shall support:

- realtime monitoring
- workflow dashboard
- collection confirmation
- notifications
- audit tracking
- retrieval operations

---

## Notifications

System shall notify production users when:

- items ready for collection
- delivery completed
- retrieval pending

---

## Monitoring Requirements

### AMR Monitoring

Telemetry includes:

- mission status
- battery
- GPS/location
- CPU usage
- autonomous mode
- safety alerts
- camera streaming
- fault status

### SMARTBox Monitoring

Monitor:

- battery level
- heartbeat
- door state
- fault events
- emergency stop

---

## Communication Protocols

| System                | Protocol       |
| --------------------- | -------------- |
| AB3/UM                | REST/JSON      |
| Kardex                | REST/API       |
| SMARTBox              | JSON-over-TCP  |
| AMR                   | WebSocket/REST |
| C2 GUI                | WebSocket      |
| Internal SB Interface | ZMQ            |

---

# ASSUMPTIONS

## Business

- AB3/UM can provide MRV JSON payloads
- SAP handles inventory validation
- vendors provide integration APIs
- users access via tablet/web app
- retrofit hardware available before MVP

---

## Technical

- stable network connectivity available
- STA provides 5G with static IP
- APIs support realtime communication
- workflow orchestration centralized in C2
- WebSocket/event-driven communication used

---

## Infrastructure

- initial POC may use separate subsystem laptops
- HA architecture not finalized
- deployment architecture undecided

---

# MISSING INFORMATION

## Business

- daily transaction volume
- concurrent workflow volume
- SLA requirements
- reporting requirements
- support model
- operational hours
- KPI/success criteria

---

## Technical

- finalized vendor APIs
- authentication model
- deployment architecture
- database selection
- retry/recovery rules
- offline handling
- firmware upgrade strategy
- queue/messaging requirement

---

## Infrastructure

- cloud vs on-prem hosting
- DR/backup requirements
- monitoring/logging platform
- network/firewall architecture
- retention policy

---

## Security

- ISO27001 scope
- encryption requirements
- RBAC model
- SSO requirements
- audit retention duration
- device authentication

---

# RISKS

## Integration Risk

Vendor APIs may:

- change
- be unstable
- be incomplete

Impact:

- workflow interruption
- development delays

---

## Hardware Risk

SMARTBox retrofit may:

- delay integration
- introduce instability
- require redesign

---

## Network Risk

System heavily depends on:

- 5G connectivity
- realtime communication
- WebSocket stability

---

## Workflow Synchronization Risk

Potential issues:

- race conditions
- duplicate commands
- stale statuses
- inconsistent workflow state

---

## Timeline Risk

POC/MVP timeline is aggressive:

- target June 2026

Risk:

- compressed testing/UAT period

---

## Operational Risk

Robot failure may cause:

- delivery interruption
- incorrect handling
- operational downtime

---

# CLARIFICATION QUESTIONS

## Business

1. Expected daily MRV volume?
2. Maximum concurrent deliveries?
3. Operational hours?
4. SLA expectations?
5. Audit retention duration?
6. Success criteria for MVP?

---

## Integration

7. Final APIs available from all vendors?
8. Sandbox/test environment available?
9. Authentication mechanism between systems?
10. Retry/acknowledgement supported?
11. Who owns orchestration responsibility?

---

## SMARTBox

12. Exact retrofit scope?
13. REST API or TCP-only integration?
14. Battery operational duration?
15. Offline handling behavior?
16. Firmware update requirement?

---

## AMR & Robotics

17. Mission retry behavior?
18. Safety escalation workflow?
19. Manual override requirement?
20. Telemetry streaming supported?
21. Fault escalation handling?

---

## Security & Infrastructure

22. Cloud or on-prem deployment?
23. ISO27001 compliance required?
24. VPN/private network required?
25. SSO integration required?
26. Backup/DR requirement?
27. Uptime SLA target?

---

# RECOMMENDED SOLUTION DIRECTION

## Architecture

- event-driven orchestration platform
- centralized workflow engine
- realtime WebSocket monitoring
- API integration layer
- device abstraction layer
- audit/event logging
- retry/recovery mechanism
- RBAC-secured portal

## Key Complexity Areas

- multi-vendor orchestration
- realtime synchronization
- robot workflow consistency
- hardware integration stability
