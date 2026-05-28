```md
# /skills/clean-architecture-review/SKILL.md

## Objective
Review implementation against Clean Architecture.

## Verify
- proper dependency direction
- thin controllers
- business logic placement
- CQRS separation
- infrastructure isolation

## Forbidden
- business logic in controllers
- infrastructure dependency in Domain
- bypassing Application layer

## Dependency Rule

Domain ← Application ← Infrastructure ← API
```
