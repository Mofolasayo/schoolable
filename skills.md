# Skills Map

This file captures the skill areas currently represented across the WorkSight workspace.

## Workspace Layout

- Flutter app root: `/Users/mofolasayo-osikoya/schoolable`
- Backend (Spring Boot): `/Users/mofolasayo-osikoya/schoolable_backend`
- Dashboard (Next.js): `/Users/mofolasayo-osikoya/schoolable_dashboard`
- Team Lead (Next.js): `/Users/mofolasayo-osikoya/schoolable_team_lead`
- Deployment artifacts only: `/Users/mofolasayo-osikoya/schoolable/schoolable_backend` (Dockerfile + service)

## Workspace Projects

### schoolable (Mobile, Flutter)
- Path: `/Users/mofolasayo-osikoya/schoolable`
- Flutter/Dart (SDK >= 3)
- Stacked (MVVM) architecture + stacked_services + codegen (build_runner, stacked_generator)
- REST API client (http) + JWT auth/session storage (flutter_secure_storage)
- WebSocket real-time messaging (web_socket_channel)
- Offline caching + local storage (sqflite, path_provider, cached_network_image)
- Push notifications (firebase_core, firebase_messaging, flutter_local_notifications)
- Device integrations: image picker/camera, geolocation, geocoding, permissions, device info
- ML Kit face detection (google_mlkit_face_detection)
- Connectivity/offline detection (connectivity_plus)
- Env/config loading (flutter_dotenv)
- UI helpers: SVGs (flutter_svg), i18n/date formatting (intl)
- Entry point: `lib/main.dart`
- Stacked config: `stacked.json`, `lib/app/app.dart`
- Generated files: `lib/app/app.router.dart`, `lib/app/app.locator.dart`, `lib/app/app.dialogs.dart`, `lib/app/app.bottomsheets.dart`
- Core services: `lib/services/backend_api_service.dart`, `lib/services/websocket_service.dart`, `lib/services/notification_service.dart`, `lib/services/logging_service.dart`
- Codegen: `flutter pub run build_runner build --delete-conflicting-outputs`
- Tests: `flutter test`, `flutter test --update-goldens`

### schoolable_backend (Spring Boot)
- Path: `/Users/mofolasayo-osikoya/schoolable_backend`
- Spring Boot 3.2 (Java 17), REST + WebSocket
- Spring WebFlux/WebClient for async HTTP calls
- Spring Security + JWT + validation (spring-boot-starter-validation)
- JPA/Hibernate + Flyway migrations
- PostgreSQL
- PostgreSQL data modeling and query tuning
- Redis cache + Spring Cache
- Bucket4j rate limiting
- OpenAPI/Swagger (springdoc)
- Cloudinary uploads
- AWS Rekognition (face match)
- PDF parsing (Apache PDFBox)
- AI workflows (Gemini, async jobs, audit logs)
- Entry point: `src/main/java/com/schoolable/backend/WorkSightBackendApplication.java`
- Config: `src/main/resources/application.yml`
- Migrations: `src/main/resources/db/migration/`
- Env validation: `com.schoolable.backend.config.RequiredEnvironmentValidator`
- Commands: `./gradlew bootRun`, `./gradlew test`, `./gradlew clean build`

### schoolable_dashboard (Super Admin, Next.js App Router)
- Path: `/Users/mofolasayo-osikoya/schoolable_dashboard`
- Next.js 15 App Router + React 19 + TypeScript
- Tailwind CSS + shadcn/ui (Radix) + class-variance-authority + tailwind-merge + clsx
- React Query (TanStack) + Zustand
- Forms/validation (React Hook Form + Zod)
- Charts/analytics (Recharts)
- Server Actions + API integration patterns
- Analytics + KPI visualizations
- UI/UX: Framer Motion, Sonner, Lucide icons, next-themes
- Testing: Vitest + Testing Library
- Entry: `src/app/`
- Shared UI: `src/components/`
- Data/utilities: `src/lib/`
- App config: `src/config/`
- Tailwind config: `tailwind.config.ts`
- Logger: `src/lib/logger.ts`
- Env check: `npm run env:check`
- Commands: `npm run dev`, `npm run build`, `npm run lint`, `npm run type-check`, `npm run test`

### schoolable_team_lead (Team Lead, Next.js App Router)
- Path: `/Users/mofolasayo-osikoya/schoolable_team_lead`
- Next.js 15 App Router + React 19 + TypeScript
- Tailwind CSS + shadcn/ui (Radix) + class-variance-authority + tailwind-merge + clsx
- React Query (TanStack) + Zustand
- Forms/validation (React Hook Form + Zod)
- Charts/analytics (Recharts)
- Team KPI insights + weekly report workflows
- Testing: Vitest + Testing Library
- Entry: `src/app/`
- Shared UI: `src/components/`
- Data/utilities: `src/lib/`
- App config: `src/config/`
- Tailwind config: `tailwind.config.ts`
- Logger: `src/lib/logger.ts`
- Env check: `npm run env:check`
- Commands: `npm run dev`, `npm run build`, `npm run lint`, `npm run type-check`, `npm run test`

## Environment and Config
- Flutter: `assets/.env` (requires `BACKEND_URL`)
- Next.js: `.env`, `.env.local`, `.env.development`, `.env.production` (requires `NEXT_PUBLIC_API_URL`)
- Backend: startup env validation; optional `SENTRY_DSN`, `SENTRY_AUTH_TOKEN`

## Codegen and Migrations
- Flutter: run build_runner after route/service/dialog/bottom-sheet/mock changes
- Backend: add Flyway migration files for schema changes

## Domain-Specific Reference

### Auth and Identity
- Endpoints (public): `POST /auth/signup`, `POST /auth/login`, `POST /auth/verify-email`, `POST /auth/resend-verification`, `POST /auth/reset-password`, `POST /auth/verify-reset-code`, `POST /auth/complete-reset`, `GET /auth/verify-link` in `schoolable_backend/src/main/java/com/schoolable/backend/auth/AuthController.java`
- JWT auth: `Authorization: Bearer <token>`; subject is user UUID and role claim is mapped to `ROLE_<ROLE>` in `schoolable_backend/src/main/java/com/schoolable/backend/auth/SecurityConfig.java`
- Email verification + reset tokens: `schoolable_backend/src/main/java/com/schoolable/backend/auth/EmailVerificationToken.java` and `schoolable_backend/src/main/java/com/schoolable/backend/auth/EmailVerificationTokenRepository.java`
- Flutter stores JWT in secure storage and in-memory cache: `schoolable/lib/services/backend_api_service.dart`
- Dashboard cookies: `admin-auth-token` in `schoolable_dashboard/src/app/login/actions.ts`, `teamlead-auth-token` in `schoolable_team_lead/src/app/login/actions.ts`

### Profiles and Org Structure
- Profile data model: `schoolable_backend/src/main/java/com/schoolable/backend/profile/Profile.java` (role/status, team lead flags, HR fields)
- Profile endpoints: `/profile/me`, `/profile/is-complete`, `/profile/complete`, `/profile/departments`, `/profile/job-levels`, `/profile/team` in `schoolable_backend/src/main/java/com/schoolable/backend/profile/ProfileController.java`
- Job levels and org structure: `schoolable_backend/src/main/java/com/schoolable/backend/hr/JobLevel.java` and `schoolable_backend/src/main/java/com/schoolable/backend/hr/HRManagementController.java`

### Attendance, Biometrics, and Time Off
- Attendance endpoints (both `/api/attendance` and `/attendance`): check-in/out, history, metrics, reference face, holidays, time off requests in `schoolable_backend/src/main/java/com/schoolable/backend/attendance/AttendanceController.java`
- Core entities: `Attendance`, `TimeOffRequest`, `OfficeLocation`, `HolidayCalendar`, `WorkSchedule`, `EmployeeWorkSchedule`, `BiometricConsent` in `schoolable_backend/src/main/java/com/schoolable/backend/attendance/`
- Reference face and device IDs live on `Profile` (see `schoolable_backend/src/main/java/com/schoolable/backend/profile/Profile.java`)

### Tasks and Work Management
- Task endpoints (both `/api/tasks` and `/tasks`): list, detail, create, status updates, comments, attachments, subtasks, ratings in `schoolable_backend/src/main/java/com/schoolable/backend/task/TaskController.java`
- Recurring tasks: `/api/tasks/recurring` in `schoolable_backend/src/main/java/com/schoolable/backend/task/RecurringTaskController.java`
- Core entities: `Task`, `TaskAssignee`, `TaskSubtask`, `TaskComment`, `TaskAttachment`, `TaskTemplate`, `RecurringTaskTemplate` in `schoolable_backend/src/main/java/com/schoolable/backend/task/`

### Announcements and Recognition
- Announcements: `/announcements` endpoints in `schoolable_backend/src/main/java/com/schoolable/backend/announcement/AnnouncementController.java`
- Recognition: `/recognitions` endpoints in `schoolable_backend/src/main/java/com/schoolable/backend/recognition/RecognitionController.java`
- Entities: `Announcement`, `AnnouncementRead`, `Recognition` in their respective packages

### Notifications and Smart Reminders
- Notifications: `/api/notifications` in `schoolable_backend/src/main/java/com/schoolable/backend/notification/NotificationController.java`
- Smart reminders (admin): `/api/admin/smart-reminders` in `schoolable_backend/src/main/java/com/schoolable/backend/notifications/SmartRemindersController.java`
- Entities: `DeviceToken`, `NotificationHistory`, `SmartReminder`

### KPI and Performance
- KPI endpoints: `/api/kpi`, `/api/individual-kpis`, `/api/kpi/config`, `/api/kpi/change-requests`, `/api/kpi-approval`, `/api/kpi/locks` (see controllers under `schoolable_backend/src/main/java/com/schoolable/backend/kpi/`)
- KPI entities: `TeamKpi`, `IndividualKpi`, `KpiHistory`, `KpiChangeRequest`, `WeeklyKpiProgress`, `WeeklyKpiContext`, `TeamQuarterlyScore`, `DepartmentPillar`, `DepartmentMetric`, `DepartmentKpiProfile`, `AiInsight`
- Performance endpoints: `/api/performance`, `/api/performance/weekly`, `/api/daily-reports`, `/api/performance/peer-feedback`, `/api/peer-helpfulness`, `/api/admin/ratings`, `/api/performance/training-records`, `/api/performance/aura-jobs`, `/aura` (see controllers under `schoolable_backend/src/main/java/com/schoolable/backend/performance/`)
- Performance entities: `PerformanceReview`, `WeeklyPerformanceReport`, `DailyReport`, `PeerFeedback`, `PeerHelpfulnessRating`, `AdminTeamLeadRating`, `TrainingRecord`, `ScoreDispute`, `DailyAuraSnapshot`, `AuraTrendAlert`, `AuraScoreJob`, `SubMetricScore`

### Team Lead Workflows
- Team lead dashboards and reports: `/api/team-lead/*` in `schoolable_backend/src/main/java/com/schoolable/backend/teamlead/TeamLeadController.java`
- Team lead approvals and org management: `/api/hr/team-leads/*` in `schoolable_backend/src/main/java/com/schoolable/backend/hr/HRManagementController.java`

### Surveys and Compliance
- Surveys: `/surveys/pulse/current`, `/surveys/pulse/{id}/respond` in `schoolable_backend/src/main/java/com/schoolable/backend/survey/SurveyController.java`
- Compliance: `/compliance/*` in `schoolable_backend/src/main/java/com/schoolable/backend/compliance/ComplianceController.java`
- Entities: `PulseSurvey`, `PulseSurveyResponse`, `CompliancePolicy`, `ComplianceSubmission`

### Storage and Media
- Upload endpoints: `/storage/upload`, `/storage/attendance/photo`, `/storage/tasks/{taskId}/attachment`, `/storage/avatar`, `/storage/announcements/{announcementId}/image` in `schoolable_backend/src/main/java/com/schoolable/backend/storage/StorageController.java`
- Used by Flutter client: `schoolable/lib/services/backend_api_service.dart`

### WebSockets and Realtime
- STOMP + native sockets: `/ws/**` and `/ws-native/**` permitted in `schoolable_backend/src/main/java/com/schoolable/backend/auth/SecurityConfig.java`
- Broadcast topics: `/topic/tasks`, `/topic/announcements`, `/topic/compliance`, user queue `/user/queue/notifications` in `schoolable_backend/src/main/java/com/schoolable/backend/websocket/WebSocketMessageController.java`

### Audit and Reference Data
- Audit logs: `/api/audit/*` in `schoolable_backend/src/main/java/com/schoolable/backend/audit/AuditController.java`
- Reference data for UI dropdowns: `/api/reference-data` in `schoolable_backend/src/main/java/com/schoolable/backend/reference/ReferenceDataController.java`

### API Contracts and Conventions
- Auth header: `Authorization: Bearer <JWT>`; most endpoints require auth except those listed in `schoolable_backend/src/main/java/com/schoolable/backend/auth/SecurityConfig.java`
- Error shapes vary: security handlers return `{"error":{"code":"...","message":"..."}}`; many controllers return `{"error":"..."}`; clients handle both (see `schoolable/lib/services/backend_api_service.dart` and `schoolable_dashboard/src/lib/api/backend.ts`)
- Some endpoints are exposed with both `/api/*` and non-`/api` paths (for example, tasks and attendance)

## Named Skill Set (Requested)
- Next.js App Router
- PostgreSQL Wizard
- API Design
- LLM Architect
- Tailwind CSS UI
- React Native Specialist (not in use; mobile client is Flutter)

## Cross-cutting Skills
- API design consistency, error handling, auth/session management
- Realtime connection lifecycle and polling fallback
- Cache invalidation and offline-first UX
- Observability via logging and diagnostics
- Web app state and data fetching (React Query + Zustand)
- Form handling and validation (React Hook Form + Zod)
- Component library patterns (shadcn/ui + Radix UI)
- Testing with Vitest + Testing Library

## Testing Skills (Needed)

### schoolable (Flutter)
- Flutter unit/widget testing (flutter_test)
- MVVM viewmodel/service testing (Stacked)
- Mocking + codegen (mockito + build_runner)
- Golden tests (golden_toolkit)
- Platform/plugin integration testing (not configured yet)

### schoolable_backend (Spring Boot)
- JUnit 5 + Spring Boot Test (spring-boot-starter-test)
- REST testing with MockMvc
- WebFlux testing with WebTestClient
- Spring Security test utilities (JWT/roles)
- JPA repository tests + Flyway migration validation
- PostgreSQL integration testing (Testcontainers if added)
- Redis/cache + rate limiting tests (embedded Redis or Testcontainers if added)
- WebSocket endpoint tests

### schoolable_dashboard (Next.js App Router)
- Vitest + Testing Library + JSDOM
- React Query/Zustand hook testing
- Form validation tests (React Hook Form + Zod)
- Server Actions/RSC integration tests
- E2E browser testing (Playwright/Cypress if added)

### schoolable_team_lead (Next.js App Router)
- Vitest + Testing Library + JSDOM
- React Query/Zustand hook testing
- Form validation tests (React Hook Form + Zod)
- KPI/report data transformation tests (Recharts)
- E2E browser testing (Playwright/Cypress if added)

### policy (Docs/Policies)
- Path: `/Users/mofolasayo-osikoya/Downloads/policy`
- Status: path not found on disk at time of scan; confirm location

### Testing Strategy Skills
- Test Architect (strategy, pyramid, isolation, contracts)
- QA Engineering (coverage, regression, E2E planning)
- Testing Automation (CI integration, flaky test reduction)

## Notes
- Firebase is only initialized when real config is provided; placeholder config skips init.
- The `schoolable/schoolable_backend/` folder contains only `Dockerfile` and `schoolable.service`; the active Spring Boot project is the sibling directory at `/Users/mofolasayo-osikoya/schoolable_backend`.
