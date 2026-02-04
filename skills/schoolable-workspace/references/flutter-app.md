# Flutter App Guide

## Entry and Bootstrap

- `lib/main.dart` loads `assets/.env` via `flutter_dotenv`.
- `lib/main.dart` validates `BACKEND_URL` at startup.
- `setupLocator()`, dialog UI, and bottom sheet UI are configured from generated
  files in `lib/app/`.
- `ConnectivityService().initialize()` runs at startup.
- Firebase initializes only when `lib/firebase_options.dart` has real values;
  otherwise the app logs a warning and skips Firebase init.

## Stacked App and Codegen

- `lib/app/app.dart` defines routes, dependencies, dialogs, and bottom sheets
  with `@StackedApp`.
- Generated outputs live in `lib/app/`:
  - `app.router.dart`
  - `app.locator.dart`
  - `app.dialogs.dart`
  - `app.bottomsheets.dart`
- Generator configuration lives in `stacked.json`.
- After changing routes, services, dialogs, bottom sheets, or test mocks, run:
  - `flutter pub run build_runner build --delete-conflicting-outputs`

## UI Structure

- Views live under `lib/ui/views/<feature>/` with paired viewmodels.
- Shared UI helpers live under `lib/ui/common/` (colors, strings, helpers).
- Use the existing `StackedView<...ViewModel>` or `ViewModelBuilder` patterns.

## Services

- `lib/services/backend_api_service.dart` reads `BACKEND_URL` from `assets/.env`.
- `lib/services/websocket_service.dart` derives WebSocket URLs from
  `BACKEND_URL`.
- `lib/services/notification_service.dart` wraps Firebase Messaging.
- `lib/services/cache_service.dart`, `database_service.dart`, and
  `connectivity_service.dart` provide local/cache utilities.
- `lib/services/logging_service.dart` centralizes client logging.

## Testing

- `test/helpers/test_helpers.dart` defines mock registrations and
  `@stacked-mock` markers.
- Viewmodel tests live under `test/viewmodels/`.
- Golden tests live under `test/golden/` and update with
  `flutter test --update-goldens`.
