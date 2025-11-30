# Mobile App Plan (ARP)

Source inputs: Web dashboard screens (Overview, Staff Performance, Tasks, Attendance, Compliance, Reports, Announcements) and PRD (`docs/PRD_ARP.md`). Platform target: Flutter, backend Supabase/Firebase.

## Goals
- Give staff and managers a clear, real-time view of KPIs, tasks, and attendance.
- Enable quick capture of attendance with GPS + photo and fast task updates.
- Keep UI consistent with the web dashboard style language while remaining mobile-first.

## Primary Users & Needs
- Staff: View personal KPIs, mark tasks done, check in/out with photo + location, read announcements, see feedback highlights.
- Managers: Monitor team KPIs, approve/verify tasks or attendance exceptions, post announcements, review reports summaries.
- HR/Admin (mobile-lite): Monitor announcements, skim KPIs, handle urgent approvals; deeper configuration remains on web.

## Navigation Model (bottom tabs)
1) Home: Personal KPI tiles, small trend chart, task and attendance quick actions, announcements snippet.  
2) Tasks: List with chip filters, completion toggles, detail sheet for subtasks/comments/attachments.  
3) Attendance: Check-in/out CTA with GPS + selfie, history list, exceptions view.  
4) Announcements: Feed of updates with status chips (Published/Scheduled/Draft) and pinning; search/filter.  
5) Profile: Role/department, recent scores, settings (notifications, language, help).

## Key Screens (MVP)
- Home Dashboard: KPI cards (Overall, Tasks, Attendance, Compliance, Feedback), mini line chart (primary stroke), today’s attendance status, top 3 tasks with checkboxes, latest announcement.
- Task List & Detail: Filters (All/Pending/In Progress/Completed/Overdue), priority chips, checkbox toggle to complete/undo, detail sheet with description, due date, tags, subtasks, comments, attachments.
- Attendance: Check-in flow (permission requests, map preview, photo capture), status badges, history with verification markers; exception notes for late/absent.
- Announcements: Feed with status chips, pinned banner, search; detail view with audience, author, schedule time, tags.
- Reports (lite, optional tab or Home widget): Latest report cards with download/view CTA opening web/PDF viewer.

## Data & Offline
- Cache last-known KPI and tasks for offline read; queue attendance check-ins and task updates for sync with conflict resolution (last-write with server timestamp).
- Leverage Supabase/Firebase auth; RLS/Firestore rules match role (staff/manager/admin).

## Backlog / Phase 1.5
- Messaging threads per manager <-> staff (per PRD “Internal Communication 1.5”).
- Manager approvals for task completion and attendance exceptions.
- Push notifications: announcements published, tasks assigned, check-in reminders.

## Non-Functional Targets
- First meaningful paint <2s on cold start; key interactions <200ms feedback.
- High-contrast text/buttons; minimum touch target 44px.
- Network resilience: retries with exponential backoff; graceful offline banners.

## Delivery Milestones
1) Foundation (Week 1): Auth shell, bottom nav, theme tokens from `mobile-style-guide.md`, API client scaffold.  
2) Tasks & Home (Week 2): Task list/detail with toggles; Home KPI cards + mini chart + task snippet.  
3) Attendance (Week 3): Check-in/out flow with GPS/photo capture and history.  
4) Announcements (Week 4): Feed, filters, detail; push hooks.  
5) Polish & QA (Week 5): Accessibility, offline caching, error states, performance tuning.

## Mobile UI Design Spec (screens and flows)
Keep visuals aligned to the web dashboard: Inter, primary #575FF4 (gradient #4248C7), pale background #F8FAFC, white cards with light borders (#E5E7EB/40). Use 12px card radius, 8px inputs/buttons, chips for filters, and minimal color noise (primary + muted neutrals; warn/error only when needed).

### Authentication & Onboarding
- Login: White background, centered card; email/password inputs with 8px radius, primary CTA “Sign in”, ghost “Forgot password”. Secondary link for SSO if available. Add subtle hero illustration tinted primary/10.  
- Onboarding carousel (3–4 slides): each slide has an illustration + short copy: Tasks, Attendance Check-In, KPI Tracking, Messaging. Pagination dots use primary/30 inactive, primary for active; skip/next buttons in header/footer.

### Home
- App bar: Logo or “Home”, profile avatar right, bell icon.  
- KPI summary row: 2x2 grid of cards (Task, Attendance, Compliance, Feedback) using primary text, muted label, and tiny trend pill (primary/10). Values 18–20pt, labels 12pt uppercase.  
- Mini trend chart: primary line over last 7 days with muted grid; optional composite if data allows.  
- Today’s tasks: list of 3 items, each row with checkbox, title, due, status chip; “View all tasks” link.  
- Quick actions: Horizontal pill buttons (Check-in, View Tasks, Messages) with icon + label, primary/ghost styles.  
- Announcements snippet: white card with status chip (Published/Scheduled), title, timestamp; tap opens detail.

### Tasks
- Task list: Filters as chips (All, Pending, In Progress, Completed, Overdue, Priority). Rows have checkbox, title, two-line description, tags, due text, status/priority pills. Progress bar for in-progress tasks (primary fill).  
- Task detail sheet/page:  
  - Header: title, status pill (Completed = primary/10 text primary; Overdue = error pill).  
  - Meta row: due date, priority pill, tags.  
  - Body: description, attachments (file pills with icon + size), subtasks with checkboxes, comments thread (avatar + text bubble), timeline entries.  
  - Actions: “Mark complete” (primary), “Add proof” (outline).  
  - Proof upload: add notes, add photo/file; show previews as chips.  
- Completion toggle must support undo (checkbox and status pill sync like web Tasks page).

### Attendance Check-in
- Hero card: shows today’s status; CTA button “Check in” (primary) or “Check out” (warn if late).  
- Capture flow:  
  1) Permission modals (camera/location).  
  2) Camera view with circular mask, shutter button primary.  
  3) Location pin preview (static map image or coordinates text).  
  4) Confirmation sheet with photo thumbnail, timestamp, location, “Submit”.  
- History list: rows with avatar/photo thumb, status pill (Present/Late/Absent), time, location line, and note. Tap opens detail with photo and verification data, mirroring web attendance modal styling.

### Announcements (In-House Communication)
- Modeled on Slack-lite but aligned to dashboard palette.  
- Channels list: pills for channels (e.g., #general, #ops) and DMs; unread dot primary.  
- Chat screen:  
  - App bar with channel name and members count.  
  - Messages as bubbles: sender name, timestamp (muted), text; attachments preview chips; voice note bubble with play button.  
  - Composer: rounded pill input, plus icons for image/file/voice; primary send button.  
- Announcement feed: retains status chips (Published/Scheduled/Draft), pinned banner, search, filters.  
- Message color use: stick to neutrals with primary accents; avoid heavy colored bubbles.

### Profile & KPI
- Profile header: avatar (40–56px), name, role, department, editable link.  
- KPI chart: 6–8 week line chart (primary), shaded area optional at 10% opacity. Legend pills muted.  
- KPI breakdown: cards or list with category label, value, progress bar.  
- Info blocks: attendance streak, tasks completed, compliance notes.  
- Settings: notification toggles, language, help, sign out; all on white cards with right-chevron.

### Design System Application
- Buttons: primary solid, outline (border #E5E7EB), ghost. Height 44px min.  
- Chips/badges: use primary/10 + primary text for positive, warn (amber/50 + amber text) sparingly, error (rose/50 + rose text) only for critical.  
- Inputs: 1px border #E5E7EB, focus ring primary/20.  
- Elevation: single soft shadow; avoid multiple shadows.  
- Transitions: 150–200ms ease, micro-scale on tap (0.98).  
- Spacing: 16px horizontal padding; 12–16px card padding; 8px gaps in rows.

### Asset & Icon Guidance
- Use Lucide/Feather set for consistency with web.  
- Illustrations: flat, low-saturation line style with primary/teal accents; avoid photo-heavy onboarding.  
- Charts: same palette as dashboard (primary, secondary lilac, amber accent).
