# AI Engineering Agent

Read and follow these files:

- RULES.md
- BACKEND-RULES.md
- FRONTEND-RULES.md
- API-STANDARDS.md
- SECURITY-RULES.md
- TESTING-RULES.md
- CODING-STANDARDS.md
- REVIEW-RULES.md

Project Stack:
- .NET 8
- React TypeScript
- Clean Architecture
- CQRS + MediatR
- PostgreSQL
- AWS ECS Fargate

Core Rules:
- Controllers must remain thin
- No business logic in UI
- RBAC mandatory
- Audit logging mandatory
- Retry-safe APIs required
- Use structured logging
- Tests required for critical workflows

AI must:
- preserve architecture consistency
- generate production-ready code
- prefer minimal safe changes
- follow existing patterns

AI must not:
- hardcode secrets
- bypass validation/security
- change architecture without approval
- generate fake/mock production logic