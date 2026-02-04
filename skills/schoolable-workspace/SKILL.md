---
name: schoolable-workspace
description: Work on the WorkSight multi-project workspace covering the Flutter mobile app, Next.js dashboard/team-lead apps, and Spring Boot backend. Use when editing Flutter views/viewmodels/services, Next.js App Router pages/components, Spring controllers/services/repos/migrations, or when coordinating env/config, dependencies, codegen, builds, and tests across these projects.
---

# WorkSight Workspace

## Overview

Make consistent changes in the WorkSight Flutter app and keep Stacked codegen, routing, services, and tests aligned.

## Quick Start

- Review the workspace map in `references/workspace-projects.md`.
- For Flutter changes, follow `references/flutter-app.md`.
- For Next.js changes, follow `references/nextjs-apps.md`.
- For backend changes, follow `references/spring-backend.md`.
- For cross-project workflows (auth, profiles, KPIs, storage, realtime), see `references/workflows.md`.

## Common Workflows

### Flutter: Add or Update a View

- Create or edit files under `lib/ui/views/<feature>/`.
- Use `StackedView<...ViewModel>` or `ViewModelBuilder` patterns already present.
- Register new screens in `lib/app/app.dart` routes.
- Regenerate code when routes, dialogs, services, or mocks change:
  - `flutter pub run build_runner build --delete-conflicting-outputs`

### Flutter: Add or Update a Service

- Implement in `lib/services/`.
- Register in `lib/app/app.dart` dependencies.
- Update test mocks in `test/helpers/test_helpers.dart` and run build_runner.

### Flutter: Run Tests

- Unit/widget tests: `flutter test`
- Golden tests: `flutter test --update-goldens`

### Next.js: Add or Update a Route/Component

- App Router pages live under `src/app/`.
- Shared UI/components live under `src/components/`.
- Run `npm run lint` or `npm run type-check` before shipping.

### Spring Boot: Add or Update an API

- Create controller/service/repo classes under `src/main/java`.
- Add Flyway migrations under `src/main/resources/db/migration/` when schema changes.
- Run `./gradlew test` and `./gradlew bootRun` as needed.

### Cross-Project: Add or Change a Data Field

- Backend: update entity + migration, then update API response/request DTOs.
- Flutter: update services + viewmodels; run build_runner if routes or mocks change.
- Next.js: update API client types and UI consumption.
- Run tests in each project.

### Cross-Project: Update Auth Flow

- Backend: update `AuthController` and `SecurityConfig` allowlists/claims.
- Flutter: update auth views and `BackendApiService` auth methods.
- Next.js: update login actions and API client response types.

### Cross-Project: Update API Contracts

- Backend: update controller request/response formats and error shapes.
- Clients: update API wrappers and UI mapping; keep error handling compatible.

## References

- `references/workspace-projects.md`
- `references/flutter-app.md`
- `references/nextjs-apps.md`
- `references/spring-backend.md`
- `references/workflows.md`
