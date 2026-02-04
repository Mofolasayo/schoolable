# Workspace Improvements

This document captures agreed improvements and the starting point for each.

## API Contract Generation (OpenAPI)

- Backend already exposes OpenAPI at `http://localhost:8081/v3/api-docs`.
- Next.js (dashboard/team lead) can generate shared types with:

```bash
npx openapi-typescript http://localhost:8081/v3/api-docs -o src/lib/api/types.ts
```

- Flutter can generate a Dart client with openapi-generator:

```bash
docker run --rm -v "$PWD:/local" openapitools/openapi-generator-cli \
  generate -i http://host.docker.internal:8081/v3/api-docs \
  -g dart -o /local/generated/api
```

## E2E Coverage

- Dashboard/Team Lead: add Playwright to each app and create smoke tests for
  auth, dashboard, and primary flows.
- Flutter: add `integration_test/` flows for login, attendance, tasks.
- Backend: add Testcontainers for PostgreSQL and Redis integration tests.

## Observability

- Flutter uses `AppLogger` in `lib/services/logging_service.dart`.
- Next.js apps use `src/lib/logger.ts`.
- Backend logs Sentry status at startup; add frontend Sentry DSNs when ready.

## Shared Design System

- Flutter tokens live in `lib/ui/common/app_colors.dart`.
- Next tokens live in `tailwind.config.ts`.
- Next step: define a shared token list and keep Flutter + Tailwind in sync.
