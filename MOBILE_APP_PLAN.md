# Mobile App Plan — Eternal Shift Mobile

## Architecture

```
┌─────────────────────────────┐
│   Eternal Shift Server      │
│  (Brain, DB, Desktop UI)    │
│       /api/v1               │
└────────────┬────────────────┘
             │ HTTP / REST
┌────────────▼────────────────┐
│   Eternal Shift Mobile      │
│   (Flutter, Android/iOS)    │
│   Pure API client           │
└─────────────────────────────┘
```

## Design Decisions

### State Management: Riverpod
- `FutureProvider.autoDispose` for all API calls
- `StateProvider` for app-level state (serverUrl, isConfigured, pollInterval)
- Simple override pattern to inject SharedPreferences and ApiClient at startup
- No complex state machines in v1

### HTTP Client: Dio
- Single `ApiClient` instance injected via `apiClientProvider`
- `updateConfig()` method allows runtime URL/token changes without app restart
- All errors mapped to `ApiException` with friendly user messages
- 10s connect timeout, 30s receive timeout

### Navigation: go_router
- Shell route wraps main tabs (Dashboard, Sessions, Approvals, Questions, Settings)
- Redirect guard sends unconfigured users to `/setup`
- Named sub-routes for session detail, conversation, proof, screenshots, etc.

### Security Storage: flutter_secure_storage
- Android: AES via EncryptedSharedPreferences
- iOS: Keychain Services
- Token loaded once at startup and injected into ApiClient
- Never displayed after save

### Polling: Timer-based
- Dashboard polls `GET /api/v1/mobile/home` every N seconds (default 8s)
- Timer cancelled when screen is disposed
- Manual refresh always available
- SSE event streams deferred to v2

## Screens Implemented

1. Server Setup (onboarding)
2. Dashboard (metrics, active sessions, attention banner, quick actions)
3. Sessions (list with filters)
4. Session Detail (info, controls, blocked panel, notes)
5. Smart Session Wizard (analyze → review → create)
6. Create Session (manual form)
7. Conversation (timeline with composer)
8. Approvals (pending/resolved, approve/reject/dismiss)
9. Questions (answer/dismiss)
10. Proof Packages (list with status indicators)
11. Tokens (summary, CLI disclosure)
12. Providers (status, no secrets)
13. Computer Actions (audit trail)
14. Screenshots (grid gallery)
15. UI Tests (scenario picker, run, results)
16. Settings (URL, token, interval, security notes, reset)

## Safety Rules Enforced

- Dangerous actions require confirmation dialogs
- `run-until-approved` requires max cycle limit (enforced in UI)
- Real provider usage shows "may consume Claude/API tokens" warning
- Approvals show "does not execute instantly" disclaimer
- No raw stack traces shown
- No infinite polling (configurable interval, disposable timer)
- Token never displayed after save

## v2 Roadmap

- SSE real-time event streaming
- Push notifications for blocked sessions
- Proof package deep detail view
- Screenshot full-screen viewer with zoom
- Cycle-by-cycle diff viewer
- Token usage charts
- Session templates browser
- Offline-first caching with Hive or Isar
- Biometric app lock
- Multiple server profiles
