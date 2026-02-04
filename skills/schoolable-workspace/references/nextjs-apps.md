# Next.js Apps Guide

## Projects

- `schoolable_dashboard` (Super Admin)
  - Path: `/Users/mofolasayo-osikoya/schoolable_dashboard`
  - Entry: `src/app/`
  - Env check: `npm run env:check`
- `schoolable_team_lead` (Team Lead)
  - Path: `/Users/mofolasayo-osikoya/schoolable_team_lead`
  - Entry: `src/app/`
  - Env check: `npm run env:check`

## Structure

- App Router pages live under `src/app/`.
- Shared UI/components live under `src/components/`.
- Utilities and data logic live under `src/lib/`.
- App configuration lives under `src/config/`.
- Tailwind config: `tailwind.config.ts`.
- Logging helper: `src/lib/logger.ts`.

## Common Commands

- Dev server: `npm run dev`
- Build: `npm run build`
- Lint: `npm run lint` (or `npm run lint:fix`)
- Type check: `npm run type-check`
- Tests: `npm run test`

## Environment Notes

- Env files supported: `.env`, `.env.local`, `.env.development`,
  `.env.production`.
- Use npm for installs and lockfiles (`package-lock.json`).
- `NEXT_PUBLIC_API_URL` is required in both apps.
