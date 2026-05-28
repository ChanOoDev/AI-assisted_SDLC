# EXECUTIVE SUMMARY

The C2 Central Management System is a warehouse automation orchestration platform designed to centralize coordination between:

* AB3/Ultramain
* Kardex ASRS/PPS
* Mobile Manipulator
* SMARTBox
* OTSAW AMR

The platform aims to automate end-to-end warehouse material workflows from MRV generation to delivery and collection while improving:

* operational efficiency
* realtime visibility
* material traceability
* accountability
* automation scalability

The MVP/POC focuses on:

* stable multi-system integration
* realtime orchestration
* autonomous delivery workflow
* centralized monitoring
* audit tracking

The platform serves as the operational control layer connecting warehouse systems, robotics systems, and delivery automation into a unified workflow ecosystem.

---

# BUSINESS PROBLEMS

## Disconnected Automation Systems

No centralized orchestration exists between:

* Kardex
* robots
* SMARTBox
* AMR
* warehouse systems

Impact:

* fragmented workflows
* manual coordination
* operational inefficiency

---

## Poor Material Traceability

Current workflows lack:

* realtime tracking
* auditability
* movement visibility
* accountability

Impact:

* lost materials
* weak operational transparency
* poor reporting capability

---

## High Manual Dependency

Operations rely heavily on:

* human coordination
* manual monitoring
* manual delivery handling

Impact:

* higher manpower cost
* increased operational delays
* inconsistent workflow execution

---

## Limited Operational Visibility

No centralized dashboard exists for:

* robot health
* delivery tracking
* workflow monitoring
* SMARTBox monitoring
* operational alerts

---

## Scalability Challenges

Existing workflows are not designed for:

* large-scale automation
* future robotics expansion
* multi-system orchestration

---

# PRODUCT GOALS

## Business Goals

* reduce manpower dependency
* improve warehouse efficiency
* improve material accountability
* reduce delivery waiting time
* enable automation scalability

---

## Operational Goals

* automate MRV-to-delivery workflow
* improve workflow consistency
* reduce operational delays
* improve realtime visibility

---

## Technical Goals

* centralized orchestration
* stable vendor integration
* resilient workflow management
* realtime monitoring capability
* scalable architecture foundation

---

## MVP Goals

* validate end-to-end automation workflow
* stabilize integrations
* validate SMARTBox operations
* validate AMR delivery workflow
* provide operational monitoring visibility

---

# USER PERSONAS

## Warehouse Operator

Responsibilities:

* monitor workflows
* supervise robot operations
* handle exceptions
* manage delivery coordination

Needs:

* realtime visibility
* operational alerts
* workflow control

---

## Production Staff

Responsibilities:

* collect requested materials
* confirm retrieval

Needs:

* realtime notifications
* simple retrieval workflow
* accurate delivery status

---

## Warehouse Supervisor

Responsibilities:

* monitor operational performance
* review delivery status
* manage operational incidents

Needs:

* dashboards
* reporting visibility
* operational traceability

---

## Maintenance Engineer

Responsibilities:

* monitor device health
* troubleshoot hardware faults
* maintain operational uptime

Needs:

* device telemetry
* fault alerts
* health monitoring

---

## System Administrator

Responsibilities:

* manage configuration
* manage users/access
* monitor platform operations

Needs:

* RBAC management
* audit logs
* system monitoring

---

# MVP SCOPE

## Included Scope

### Workflow Orchestration

* MRV ingestion
* workflow lifecycle management
* task sequencing
* workflow tracking

---

### Device Integration

* Kardex integration
* Mobile Manipulator integration
* SMARTBox integration
* OTSAW AMR integration

---

### SMARTBox Operations

* compartment assignment
* open/close control
* battery monitoring
* occupancy monitoring
* fault monitoring

---

### AMR Operations

* delivery mission assignment
* pickup workflow
* mission tracking
* return-home workflow

---

### Monitoring Dashboard

* realtime workflow monitoring
* robot monitoring
* SMARTBox monitoring
* alert visibility

---

### User Portal

* retrieval interface
* collection confirmation
* notification workflow

---

### Audit & Logging

* workflow logs
* operational logs
* command tracking
* event tracking

---

# FUNCTIONAL REQUIREMENTS

## MRV Integration

System shall:

* receive MRV JSON payloads
* validate payload structure
* create workflows automatically

---

## Workflow Engine

System shall:

* orchestrate automation workflows
* maintain workflow states
* support retries/recovery
* persist workflow history

---

## Mobile Manipulator Integration

System shall:

* trigger packing workflow
* receive packing completion
* receive robot telemetry
* receive fault alerts

---

## SMARTBox Management

System shall:

* assign compartments
* open/close doors
* monitor battery status
* receive heartbeat events
* receive fault events

---

## AMR Integration

System shall:

* assign delivery missions
* trigger pickup/delivery
* monitor mission status
* monitor battery/GPS
* trigger return-home workflow

---

## Notifications

System shall:

* notify users when items are ready
* notify operational alerts
* provide realtime status updates

---

## User Operations

Users shall:

* authenticate before retrieval
* confirm collection
* view delivery status

---

## Audit & Logging

System shall:

* log workflow transitions
* log device commands
* log user actions
* maintain immutable audit history

---

# NON-FUNCTIONAL REQUIREMENTS

## Availability

Target:

* 99.5% uptime for MVP operations

---

## Performance

Targets:

* API response < 2 sec
* realtime updates < 1 sec
* workflow processing < 3 sec

---

## Scalability

Architecture shall support:

* additional robots
* additional SMARTBoxes
* future multi-site expansion

---

## Reliability

System shall:

* support retry handling
* recover from temporary disconnects
* prevent duplicate workflow execution

---

## Security

System shall support:

* JWT authentication
* RBAC authorization
* HTTPS/TLS encryption
* audit logging

---

## Maintainability

System shall provide:

* centralized logging
* monitoring visibility
* modular integration architecture

---

# RISKS

## Integration Risk

Vendor APIs may:

* change frequently
* be unstable
* lack documentation

Impact:

* workflow interruption
* development delays

---

## Hardware Risk

SMARTBox retrofit may:

* delay implementation
* introduce instability
* require redesign

---

## Network Risk

Realtime orchestration depends heavily on:

* 5G connectivity
* WebSocket stability
* low-latency communication

---

## Synchronization Risk

Potential issues:

* race conditions
* stale workflow state
* duplicate commands
* inconsistent telemetry

---

## Timeline Risk

MVP timeline is aggressive.

Impact:

* compressed UAT period
* limited stabilization time

---

## Operational Risk

Robot or delivery failures may:

* interrupt operations
* delay deliveries
* impact user confidence

---

# ROADMAP

# Phase 1 — MVP / POC

Focus:

* integration feasibility
* workflow orchestration
* realtime monitoring
* operational validation

Capabilities:

* MRV workflow
* SMARTBox operations
* AMR delivery workflow
* centralized dashboard
* audit tracking

---

# Phase 2 — Stabilization

Focus:

* reliability improvement
* monitoring enhancement
* operational hardening
* workflow optimization

Potential Features:

* advanced alerts
* SLA monitoring
* operational analytics
* enhanced recovery mechanisms

---

# Phase 3 — Intelligent Automation

Focus:

* predictive operations
* AI-assisted optimization
* advanced analytics

Potential Features:

* predictive maintenance
* intelligent routing
* operational forecasting
* workflow optimization

---

# Phase 4 — Enterprise Expansion

Focus:

* multi-site orchestration
* enterprise scalability
* centralized operations management

Potential Features:

* enterprise reporting
* cross-site coordination
* advanced governance
* large-scale automation support
