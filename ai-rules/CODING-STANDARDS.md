# CODING-STANDARDS.md

## Goal
Write simple, secure, readable, maintainable production code.

## General
- Prefer clarity over cleverness.
- Keep changes small and reviewable.
- Follow existing project style.
- Avoid unnecessary abstractions.
- Avoid duplicated business logic.
- Use meaningful names.
- Keep methods/classes focused.
- Remove dead code.
- Do not leave production TODOs.
- Do not introduce new libraries without reason.

## Naming
- Use clear domain names.
- Avoid vague names: data, item, temp, helper.
- Commands: `CreateXCommand`, `UpdateXCommand`.
- Queries: `GetXQuery`, `SearchXQuery`.
- Handlers: `CreateXCommandHandler`.
- Validators: `CreateXCommandValidator`.
- DTOs: `XRequest`, `XResponse`, `XDto`.
- Interfaces: prefix with `I`.

## C#
- Use async/await for I/O.
- Use cancellation tokens where applicable.
- Use nullable reference types correctly.
- Avoid static mutable state.
- Avoid magic strings/numbers.
- Prefer constants/enums/value objects.
- Use guard clauses for validation.
- Do not swallow exceptions.
- Do not expose stack traces to clients.

## TypeScript
- Use strict typing.
- Avoid `any` unless justified.
- Prefer typed API clients.
- Keep components small.
- Extract reusable logic to hooks/services.
- Avoid business logic in UI components.
- Handle loading, error, empty, and success states.

## Formatting
- Keep consistent indentation.
- Keep imports clean.
- Group related code.
- Keep files reasonably small.
- Use comments only when logic is not obvious.

## Error Handling
- Use centralized backend exception handling.
- Return standard API errors.
- Log exceptions with correlation ID.
- Show user-friendly frontend errors.
- Never leak sensitive details.

## Security
- No hardcoded secrets.
- No sensitive data in logs.
- Validate all external input.
- Enforce authorization server-side.
- Follow OWASP principles.

## Performance
- Avoid unnecessary DB queries.
- Avoid N+1 queries.
- Use pagination for large lists.
- Cache only with clear invalidation.
- Avoid premature optimization.

## Done Criteria
- Code builds.
- Tests pass.
- Validation included.
- Security impact checked.
- Logging/audit impact checked.
- No broken public contracts.