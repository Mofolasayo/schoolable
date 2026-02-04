# Spring Boot Backend Guide

## Project

- Path: `/Users/mofolasayo-osikoya/schoolable_backend`
- Build tool: Gradle (`build.gradle`, `gradlew`)
- Java: 17 (toolchain configured in `build.gradle`)
- Entry point: `src/main/java/com/schoolable/backend/WorkSightBackendApplication.java`

## Structure

- Controllers/services/repos under `src/main/java/com/schoolable/backend/`.
- Config and application settings in `src/main/resources/application.yml`.
- Flyway migrations in `src/main/resources/db/migration/`.
- Startup env validation runs via `RequiredEnvironmentValidator` in
  `com.schoolable.backend.config`.

## Common Commands

- Run locally: `./gradlew bootRun`
- Run tests: `./gradlew test`
- Build: `./gradlew clean build`

## Notes

- Flyway runs on startup; add a new migration file for schema changes.
- Sentry auth uses `SENTRY_AUTH_TOKEN` if set in the environment.
- `SENTRY_DSN` is optional and logged at startup.
