```md
# /skills/backend-development/SKILL.md

## Objective
Implement enterprise-grade .NET 8 backend features using:
- Clean Architecture
- CQRS
- MediatR
- EF Core
- PostgreSQL
- JWT + RBAC

## Required Rules
- Controllers thin
- Business logic in Application/Domain
- Validation mandatory
- Structured logging required
- RBAC mandatory
- Audit logging required
- Use standard response envelope

## Implementation Flow
1. Read specs
2. Identify domain rules
3. Create command/query
4. Create validator
5. Create handler
6. Add infrastructure logic
7. Add endpoint
8. Add tests

## Forbidden
- fat controllers
- hardcoded secrets
- skipping validation
- direct DB access from controller
- swallowing exceptions
```