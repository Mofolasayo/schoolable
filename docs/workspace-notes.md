# WorkSight Workspace Notes

Quick reference for the current workspace on this machine.

## Projects

- Flutter mobile app: `schoolable/`
- Spring Boot backend: `schoolable_backend/`
- Next.js dashboard: `schoolable_dashboard/`
- Next.js team lead: `schoolable_team_lead/`

## Mobile App (Flutter)

- Stack: Flutter 3, Stacked (MVVM), `flutter_dotenv`, CachedNetworkImage,
  Flutter SVG, Firebase Messaging.
- Entry: `lib/main.dart` loads `assets/.env`, sets up Stacked services/router,
  initializes Firebase when config is valid, and starts at `StartupView`.
- Navigation/DI: `lib/app/app.dart` defines routes/services/bottom-sheets/dialogs;
  generated files in `lib/app/`.
- Backend API: `lib/services/backend_api_service.dart` handles auth/profile and
  app data via REST + JWT; `lib/services/websocket_service.dart` handles realtime
  messaging via `/ws-native`.
- Primary UI areas: auth, onboarding, home, tasks, chat, attendance, compliance,
  profile, reports.
- Docs: `docs/mobile-app-plan.md` and `docs/mobile-style-guide.md`.
- Env: needs `assets/.env` with `BACKEND_URL`.

## Backend (Spring Boot)

- Stack: Spring Boot 3.2, JPA/Hibernate + Flyway, PostgreSQL, Redis (optional),
  WebSocket, JWT auth, Springdoc OpenAPI.
- Entry: `src/main/java/com/schoolable/backend/WorkSightBackendApplication.java`.
- Config: `src/main/resources/application.yml`, env-driven.
- Key modules: auth, profile, attendance, tasks, performance/KPI, compliance,
  notifications, websocket, AI jobs, storage.

## Dashboard (Next.js)

- Stack: Next.js 15 (App Router), TypeScript, Tailwind + shadcn/ui,
  React Hook Form + Zod, Vitest, React Query + Zustand.
- Auth/API: `src/lib/api/backend.ts` handles token-based calls to the backend;
  `src/config/env.ts` validates required env vars.
- UI: routes live under `src/app/`, shared UI in `src/components/`.
- Docs in `schoolable_dashboard/docs/` for product, architecture, and AI guides.

## Team Lead (Next.js)

- Stack: Next.js 15 (App Router), TypeScript, Tailwind + shadcn/ui,
  Vitest, React Query + Zustand.
- Auth/API: `src/lib/api/team-lead.ts` (server actions) and
  `src/lib/api/backend-url.ts` for backend URL resolution.
- UI: dashboard/analytics/settings/support routes under `src/app/(dashboard)`.

## Shared Next Steps (suggested)

- Align API contracts via OpenAPI generation and typed clients.
- Add E2E coverage (Playwright) for both Next apps.
- Add integration tests for Flutter flows and Testcontainers for backend.
- Standardize logging/observability and error handling across clients.
