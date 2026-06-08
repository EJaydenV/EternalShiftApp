# CLAUDE.md — Eternal Shift Mobile

## Project Overview

Flutter mobile app — professional companion client for the Eternal Shift AI orchestration server.
This is a **pure API client**. No LLM runs locally. No database access.

## Critical Architecture Rule

```
Eternal Shift Server  →  brain, orchestration, DB, desktop UI, /api/v1
Eternal Shift Mobile  →  mobile UI calling /api/v1 only
```

Never add logic that:
- Runs LLMs locally
- Accesses the server database directly
- Executes shell commands
- Duplicates server orchestration

## Stack

- Flutter 3.x / Dart 3.x
- flutter_riverpod (state management)
- dio (HTTP client)
- go_router (navigation)
- flutter_secure_storage (secure token storage)
- shared_preferences (non-sensitive settings)
- intl (date formatting)

## Project Structure

```
lib/
  main.dart           — Entry point: loads SharedPreferences + ApiClient, wraps ProviderScope
  app.dart            — GoRouter definition, MainShell (bottom nav), EternalShiftApp widget

  core/
    api/
      api_client.dart    — Single Dio-based API client for all /api/v1 calls
      api_exception.dart — Typed exception with userMessage helper
      endpoints.dart     — All /api/v1 path constants and helpers
      providers.dart     — All Riverpod FutureProviders and StateProviders

    config/
      app_config.dart    — App-wide constants (default URL, poll interval, max cycles)

    models/             — Pure data classes with fromJson() factory
      api_response.dart
      session.dart
      cycle.dart
      conversation_event.dart
      approval.dart
      question.dart
      proof_package.dart
      token_usage.dart
      provider_status.dart
      computer_action.dart
      screenshot.dart
      ui_test_run.dart
      system_status.dart

    storage/
      settings_storage.dart  — SharedPreferences + FlutterSecureStorage wrapper

    theme/
      app_theme.dart    — Dark theme (navy/graphite, electric blue/cyan/violet accents)

    widgets/            — Shared reusable widgets
      status_badge.dart
      metric_card.dart
      loading_state.dart
      empty_state.dart
      error_state.dart
      confirm_dialog.dart
      section_card.dart

  features/           — One folder per screen area
    onboarding/       — server_setup_screen.dart
    dashboard/        — dashboard_screen.dart
    sessions/         — sessions_screen.dart, session_detail_screen.dart,
                        create_session_screen.dart, smart_session_wizard_screen.dart
    conversation/     — conversation_screen.dart
    approvals/        — approvals_screen.dart, approval_detail_screen.dart
    questions/        — questions_screen.dart
    proof/            — proof_screen.dart, proof_detail_screen.dart
    tokens/           — tokens_screen.dart
    providers/        — providers_screen.dart
    computer_actions/ — computer_actions_screen.dart
    screenshots/      — screenshots_screen.dart, screenshot_detail_screen.dart
    ui_tests/         — ui_tests_screen.dart
    settings/         — settings_screen.dart
```

## State Management Pattern

All API data uses `FutureProvider.autoDispose` (with `.family` when session-scoped).
Refresh by calling `ref.invalidate(provider)`.

App-level mutable state uses `StateProvider`:
- `isConfiguredProvider` — onboarding complete?
- `serverUrlProvider` — current server URL
- `pollIntervalProvider` — refresh interval in seconds

`ApiClient` is a plain class (not a provider) — it is created once in `main.dart`
and injected via `apiClientProvider.overrideWithValue(client)`.

`updateConfig(baseUrl:, token:)` mutates the Dio instance in place — used after settings changes.

## API Response Format

```json
{ "ok": true, "data": {}, "message": "..." }
{ "ok": false, "error": { "code": "...", "message": "...", "details": {} } }
```

All API calls go through `ApiClient`. All errors become `ApiException`.
`ApiException.userMessage` returns human-readable text (no stack traces).

## Safety Rules (Do Not Bypass)

1. **Confirmation dialogs required** for: stop, delete, approve, run cycle with real provider,
   run-until-approved, change server URL, change token
2. **run-until-approved** must always send `max_cycles` in the request body
3. **Real provider warning** must show "may consume Claude/API tokens" before any cycle run
4. **Approval warning** must show "does not execute instantly" on every approval action
5. **Token never displayed** after save — show masked state only
6. **No raw stack traces** — always use `ApiException.userMessage`

## Theme Values (AppTheme)

```dart
background: Color(0xFF0B0F1A)   // deep navy
surface:    Color(0xFF131929)   // slightly lighter
card:       Color(0xFF1A2236)   // card bg
accentBlue: Color(0xFF3B82F6)
accentCyan: Color(0xFF06B6D4)
accentViolet: Color(0xFF8B5CF6)
success: Color(0xFF22C55E)
warning: Color(0xFFF59E0B)
danger:  Color(0xFFEF4444)
textPrimary:   Color(0xFFE2E8F0)
textSecondary: Color(0xFF94A3B8)
textMuted:     Color(0xFF475569)
```

## Adding a New Screen

1. Create `lib/features/<area>/<name>_screen.dart`
2. Add route in `app.dart` GoRouter routes list
3. Add navigation entry if needed (settings, session detail nav links, etc.)
4. Add API method to `ApiClient` if needed
5. Add `FutureProvider` in `core/api/providers.dart` if needed

## Running

```bash
flutter pub get
flutter run                   # default device
flutter run -d android        # Android
flutter run -d ios            # iOS (requires macOS + Xcode)
flutter test                  # unit tests
```

## iOS Build Notes

iOS requires macOS + Xcode. On first build:
```bash
cd ios && pod install && cd ..
flutter run -d ios
```

The project uses bundle ID: `com.eternalshift.mobile`
Minimum iOS version: 12.0

## Android Build Notes

Minimum SDK: 21 (Android 5.0)
Target SDK: 34
Bundle ID: `com.eternalshift.mobile`

`android/local.properties` must have `flutter.sdk` set (auto-generated by flutter).
`AndroidManifest.xml` has `android:usesCleartextTraffic="true"` for local HTTP dev server.

## Tests

Tests are in `test/widget_test.dart`.
Tests cover: ApiResponse parsing, ApiException, Session/Approval/Question/Proof models,
SettingsStorage, ApiClient construction.

Run: `flutter test`

## Git & Versioning

Remote: https://github.com/EJaydenV/EternalShiftApp
Commit every working version with clear commit messages.

## What NOT to do

- Do not add local LLM, database, or shell execution
- Do not store secrets in SharedPreferences (use flutter_secure_storage)
- Do not show raw API tokens after save
- Do not allow run-until-approved without max cycle limit
- Do not add comments explaining what code does (names do that)
- Do not overcomplicate with premature abstractions
