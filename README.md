# WorkSight Workspace

This workspace spans multiple projects on this machine.

Projects:
- Flutter mobile app: `/Users/mofolasayo-osikoya/schoolable`
- Spring Boot backend: `/Users/mofolasayo-osikoya/schoolable_backend`
- Next.js dashboard: `/Users/mofolasayo-osikoya/schoolable_dashboard`
- Next.js team lead: `/Users/mofolasayo-osikoya/schoolable_team_lead`

## Quick Start Matrix

| Project | Path | Dev Command | Env Example |
| --- | --- | --- | --- |
| Flutter app | `/Users/mofolasayo-osikoya/schoolable` | `flutter run` | `assets/.env.example` |
| Backend | `/Users/mofolasayo-osikoya/schoolable_backend` | `./gradlew bootRun` | `.env.example` |
| Dashboard | `/Users/mofolasayo-osikoya/schoolable_dashboard` | `npm run dev` | `.env.example` |
| Team lead | `/Users/mofolasayo-osikoya/schoolable_team_lead` | `npm run dev` | `.env.example` |

## Flutter App (schoolable)

- Install deps: `flutter pub get`
- Generate Stacked code: `flutter pub run build_runner build --delete-conflicting-outputs`
- Run: `flutter run`
- Tests: `flutter test`

## Golden Tests

Golden tests are already setup for this project. To run the tests and update the golden files, run:

```bash
flutter test --update-goldens
```

The golden test screenshots will be stored under `test/golden/`.

## Backend (schoolable_backend)

- Install deps: `./gradlew build` (or `./gradlew test`)
- Run: `./gradlew bootRun`
- OpenAPI: `http://localhost:8081/v3/api-docs`

## Dashboard (schoolable_dashboard)

- Install deps: `npm install`
- Run: `npm run dev`
- Validate env: `npm run env:check`
- Tests: `npm run test`

## Team Lead (schoolable_team_lead)

- Install deps: `npm install`
- Run: `npm run dev`
- Validate env: `npm run env:check`
- Tests: `npm run test`
