# TESTING-RULES.md

## Goal
Tests must prove business correctness, security behavior, and regression safety.

## General
- Test critical business rules.
- Test happy path and failure path.
- Prefer clear tests over many weak tests.
- Tests must be deterministic.
- Avoid real external services in unit tests.
- Use meaningful test names.
- Keep Arrange/Act/Assert clear.

## Backend
Use xUnit.

Required tests:
- domain rules
- validators
- CQRS handlers
- authorization-sensitive behavior
- API response behavior
- error handling
- concurrency-sensitive logic
- audit/logging trigger points where practical

Mock:
- external APIs
- RabbitMQ
- Redis
- AWS services
- time/provider dependencies

Do not mock:
- pure domain logic unnecessarily.

## Frontend
Use React Testing Library.

Required tests:
- user-visible behavior
- form validation
- loading/error/empty/success states
- role-based visibility
- route protection
- API failure handling

Avoid:
- testing implementation details
- testing private functions directly
- fragile snapshot-heavy tests

## API / Integration
Test:
- auth required
- RBAC enforced
- validation errors
- standard response envelope
- status codes
- idempotency where applicable
- retry/failure behavior where applicable

## Security Tests
Verify:
- unauthorized access blocked
- forbidden access blocked
- invalid tokens rejected
- sensitive data not exposed
- validation prevents bad input

## Messaging Tests
For RabbitMQ flows verify:
- message handler idempotency
- retry behavior
- dead-letter behavior
- duplicate message handling
- failure logging

## Data Tests
Verify:
- migrations apply cleanly
- required fields enforced
- soft delete behavior
- optimistic concurrency
- transaction rollback behavior

## Test Naming
Use readable names:

```text
MethodOrFeature_Should_ExpectedResult_When_Condition