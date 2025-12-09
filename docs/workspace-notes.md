# Schoolable Workspace Notes

Quick reference for both codebases on this machine.

## Projects
- Flutter mobile app: `schoolable/`
- Next.js dashboard: `schoolable_dashboard/`

## Mobile App (Flutter)
- Stack: Flutter 3, Stacked (MVVM), Supabase, `flutter_dotenv`, CachedNetworkImage, Flutter SVG.
- Entry: `lib/main.dart` loads `assets/.env`, initializes Supabase, registers Stacked services/router, starts at `StartupView` (redirects to `LoginView` or `HomeView` based on auth).
- Navigation/DI: `lib/app/app.dart` defines routes/services/bottom-sheets/dialogs; generated files in `lib/app/`.
- Auth flow: `LoginView` uses `SupabaseService.signIn`; incomplete profiles are routed to `CompleteProfileView` (collects department/role/date joined/etc. and calls `updateProfile`). `SignupView` uses Supabase email/password sign-up and prompts email verification. `ForgotPasswordView` triggers `resetPasswordForEmail`.
- Supabase integration: `lib/services/supabase_service.dart` centralizes auth, profile CRUD+cache, announcements (read/unread), tasks (list/detail, status/progress updates, comments, subtasks), and chat (channels/DMs/messages). DiceBear avatars generated when missing.
- Home: `lib/ui/views/home/` shows KPI tiles, task distribution bar, announcements (with sheet + mark-as-read), and "today's tasks" sourced from Supabase tasks. Polling every 2 minutes; uses cached profile to avoid flicker.
- Tasks: `lib/ui/views/tasks/` lists assigned tasks with filters/search; detail view supports subtasks toggles, optimistic comments, mark-as-complete, and realtime/polling via Supabase channels. `create_task_view.dart` is a local form stub (not wired to Supabase).
- Chat: `lib/ui/views/chat/` lists channels + DMs from Supabase membership, supports DM creation and channel creation (with member picker), and renders messages in `MessageDetailView` with realtime inserts + polling fallback.
- Profile: `lib/ui/views/profile/` shows profile info pulled from Supabase (with DiceBear fallback) and supports logout.
- Attendance: `lib/ui/views/attendance/` is UI-only placeholder; `SupabaseService.checkIn` exists but UI is not wired (camera/GPS capture not implemented).
- Docs: `docs/mobile-app-plan.md` (feature plan) and `docs/mobile-style-guide.md` (design system). PRD referenced in plan (`docs/PRD_ARP.md`) is missing in this repo.
- Env: needs `assets/.env` with `SUPABASE_URL` and `SUPABASE_ANON_KEY` (listed in `IMPLEMENTATION_PLAN.md` in dashboard repo).

## Dashboard (Next.js)
- Stack: Next.js 15 (App Router), TypeScript strict, Tailwind + shadcn/ui, TanStack Query, Zustand, Supabase, React Hook Form + Zod, Vitest.
- Auth: `/login` page uses Supabase sign-in but currently gated by hard-coded admin credentials in `src/app/login/actions.ts` (update to env-backed). `middleware.ts` calls `updateSession` to enforce auth on non-public routes. Logout in same actions file.
- Layout/nav: `src/components/layouts/DashboardLayout.tsx` renders sidebar/header using `src/config/navigation.ts`; fetches Supabase user/profile for header avatar. Dashboard group routed via `src/app/(dashboard)/layout.tsx`.
- Pages (all under `src/app/(dashboard)/dashboard/`):
  - `page.tsx`: Overview with static KPI/graph/task distribution widgets.
  - `tasks/page.tsx`: Rich task table/detail overlay; wired to Supabase server actions (`src/app/actions/tasks.ts`) for CRUD, comments, subtasks, and progress recalculation, but still ships mock task data for initial render.
  - `announcements/page.tsx`: CRUD using `src/app/actions/announcements.ts` (supports scheduled → published auto-toggle); `loading.tsx` skeleton.
  - `users/page.tsx` + `StaffDirectoryClient.tsx`: fetch staff profiles (service role key optional) via `getStaffProfiles`.
  - `staff/page.tsx`, `attendance/page.tsx`, `compliance/page.tsx`, `reports/page.tsx`, `communication/page.tsx`, `insights/page.tsx`, `settings/page.tsx`: UI stubs/placeholders.
- Supabase: Client/server helpers in `src/lib/supabase/`. Session-aware middleware blocks unauthenticated access. Environment expects `.env.local` with `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY` (service role optional for staff fetch).
- Docs in `schoolable_dashboard/docs/`: PRD (`PRD_ARP.md`), `WORKSPACE_OVERVIEW.md` (summarizes both apps), `ARCHITECTURE.md`, `CONVENTIONS.md`, `AI_AGENT_GUIDE.md`, `IMPLEMENTATION_SUMMARY.md`. Root `IMPLEMENTATION_PLAN.md` + `SUPABASE_SETUP.md` describe schema and setup steps.

## Shared Next Steps (suggested)
- Provision Supabase with `SUPABASE_SETUP.md` SQL; fill `.env.local` and `assets/.env`.
- Replace hard-coded admin credentials with env-driven auth flow; ensure middleware routes to `/login` appropriately.
- Wire mobile attendance UI to `SupabaseService.checkIn` with camera/GPS capture and history; add announcement read-status caching.
- Replace mock data in dashboard `tasks/page.tsx` with Supabase data and align task/announcement schemas between mobile and dashboard.
