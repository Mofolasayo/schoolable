# Extended Workflows

Use these when a change spans the backend and one or more client apps. Pair them
with the project-specific guides in this skill.

## Cross-Project: Add or Change a Profile Field

Backend
- Update entity: `schoolable_backend/src/main/java/com/schoolable/backend/profile/Profile.java`.
- Add Flyway migration in `schoolable_backend/src/main/resources/db/migration/`.
- Update profile response builders in `AuthController` and `ProfileController`.

Flutter
- Update profile mapping in `schoolable/lib/services/backend_api_service.dart`.
- Update profile forms and viewmodels under `schoolable/lib/ui/views/auth/` or profile views.
- Run build_runner if routes or mocks changed.

Dashboard
- Update `StaffProfile` types in `schoolable_dashboard/src/lib/api/backend.ts`.
- Update login cookie payload in `schoolable_dashboard/src/app/login/actions.ts` if needed.

Team Lead
- Update API types and mapping in `schoolable_team_lead/src/lib/api/team-lead.ts`.
- Update login cookie payload in `schoolable_team_lead/src/app/login/actions.ts` if needed.

## Cross-Project: Auth Flow Changes (Signup/Login/Verification/Reset)

Backend
- Update endpoints in `schoolable_backend/src/main/java/com/schoolable/backend/auth/AuthController.java`.
- Adjust public allowlist and JWT claims in `schoolable_backend/src/main/java/com/schoolable/backend/auth/SecurityConfig.java` and `JwtService`.
- Update verification/reset token logic if needed (`EmailVerificationToken`).

Flutter
- Update auth methods in `schoolable/lib/services/backend_api_service.dart`.
- Update auth screens under `schoolable/lib/ui/views/auth/`.

Dashboard + Team Lead
- Update login actions (`schoolable_dashboard/src/app/login/actions.ts`,
  `schoolable_team_lead/src/app/login/actions.ts`).
- Update API client response types (`schoolable_dashboard/src/lib/api/backend.ts`,
  `schoolable_team_lead/src/lib/api/team-lead.ts`).

## Cross-Project: API Contract Change (Any Endpoint)

Backend
- Update controller request/response formats and error shapes.
- If schema changes, add a Flyway migration.

Clients
- Update API wrappers and types (Flutter `BackendApiService`,
  Dashboard `backend.ts`, Team Lead `team-lead.ts`).
- Keep error handling compatible with both `{"error":"..."}` and
  `{"error":{"code":"...","message":"..."}}` patterns.

## File Upload or Media Changes

Backend
- Update endpoints in `schoolable_backend/src/main/java/com/schoolable/backend/storage/StorageController.java`.
- Adjust storage service integration if needed (Cloudinary configs, paths).

Flutter
- Update upload helpers in `schoolable/lib/services/backend_api_service.dart`.
- Ensure auth headers and content types are set correctly.

Next.js
- Use `FormData` and do not set `Content-Type` manually.
- Team Lead upload route: `schoolable_team_lead/src/app/api/upload/route.ts`.

## Realtime + Notifications

Backend
- Broadcast updates in `schoolable_backend/src/main/java/com/schoolable/backend/websocket/WebSocketMessageController.java`.
- Ensure websocket endpoints are allowed in `SecurityConfig` as needed.

Flutter
- Update subscriptions in `schoolable/lib/services/websocket_service.dart`.

Dashboard
- Update websocket token flow in `schoolable_dashboard/src/lib/websocket-wrapper.tsx`.

## Reference Data + Feature Flags

Backend
- Update `schoolable_backend/src/main/java/com/schoolable/backend/reference/ReferenceDataController.java`.
- Update flags in `schoolable_backend/src/main/java/com/schoolable/backend/config/FeatureFlags.java` if needed.

Clients
- Update reference data types and selectors in `schoolable_team_lead/src/lib/api/team-lead.ts`.
- Update any dashboard UI that relies on reference data.

## KPI / Performance Changes

Backend
- Update KPI and performance controllers under `schoolable_backend/src/main/java/com/schoolable/backend/kpi/` and
  `schoolable_backend/src/main/java/com/schoolable/backend/performance/`.
- Update related entities and migrations if needed.

Clients
- Update team lead data mappings in `schoolable_team_lead/src/lib/api/team-lead.ts`.
- Update dashboard analytics pages and chart transforms in `schoolable_dashboard/src/app/`.

## Testing and Validation

- Backend: `./gradlew test` (and `./gradlew bootRun` for manual checks).
- Flutter: `flutter pub run build_runner build --delete-conflicting-outputs`, then `flutter test`.
- Next.js: `npm run lint`, `npm run type-check`, `npm run test` in each app.
