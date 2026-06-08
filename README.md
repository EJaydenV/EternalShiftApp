# Eternal Shift Mobile

Professional AI orchestration control center — mobile companion for the Eternal Shift server.

## What is this?

Eternal Shift Mobile is a Flutter mobile app for managing autonomous LLM orchestration sessions
running on your Eternal Shift server. It is a **companion client only** — all intelligence,
sessions, database, and orchestration run on the server.

```
Eternal Shift Server  →  Brain, orchestration, database, desktop UI, /api/v1
Eternal Shift Mobile  →  Mobile control interface calling /api/v1
```

The server ships with its own desktop web UI. This mobile app is an additional companion
that lets you monitor and control sessions from your phone.

## Features

- Create and manage AI sessions
- Smart session wizard (AI-powered goal analysis)
- Run cycles, pause, resume, stop sessions
- Answer AI questions
- Approve or reject sensitive requests (with safety warnings)
- View full conversation timeline (Worker → Reviewer → Supervisor)
- Add notes, feedback, and comments
- View proof packages with test results and evidence
- Token usage and efficiency metrics
- Provider status (Mock, Claude CLI, Anthropic API)
- Browser / computer action audit trail
- Screenshot gallery
- Run UI test scenarios against the server
- Real-time updates via polling

## Stack

- Flutter 3.x (Android-first, iOS-ready)
- Riverpod (state management)
- Dio (HTTP client)
- go_router (navigation)
- flutter_secure_storage (token storage)
- shared_preferences (settings)

## Running the App

### Prerequisites

1. Install [Flutter SDK](https://docs.flutter.dev/get-started/install) (≥3.3.0)
2. Have your Eternal Shift server running
3. Android Studio or VS Code with Flutter extension

### Setup

```bash
flutter pub get
flutter run
```

### Android

```bash
flutter run -d android
```

### iOS

```bash
cd ios && pod install && cd ..
flutter run -d ios
```

## Configuring Server URL

On first launch, you will see the Server Setup screen.

**Local development (emulator):**
```
http://127.0.0.1:8765
```

**Physical device on same network:**
```
http://192.168.x.x:8765
```
Replace `192.168.x.x` with your computer's LAN IP address.
Both your computer and phone must be on the same Wi-Fi network.

**Finding your LAN IP:**
- Windows: `ipconfig` → look for IPv4 Address
- Mac/Linux: `ifconfig` or `ip addr`

## Authentication

The app uses Bearer token authentication:

```http
Authorization: Bearer <your-token>
```

The token is stored in encrypted secure storage on the device. It is never displayed
again after saving. If you need to update it, go to Settings and enter a new token.

## Creating Sessions

1. Tap **Sessions** in the bottom navigation
2. Tap **Smart Session** (recommended) to use AI-guided goal analysis
3. Enter your goal in plain language (e.g. "Create a website for my business")
4. Tap **Analyze Goal** — the server will analyze your input
5. Review the detected session type, risk level, and first tasks
6. Tap **Create Session** or **Create and Run One Cycle**

## Answering Approvals and Questions

When a session is blocked:

- **Approvals** tab shows sensitive requests awaiting your decision
- **Questions** tab shows AI questions needing your input

Important: Approving does **not** instantly execute the action.
It marks the approval so the next safe server-side cycle can continue.

## Viewing Proof and Tokens

- **Proof Packages**: evidence of completed tasks (tests, files changed, screenshots, verdicts)
- **Tokens**: usage today, by session, by provider, cache efficiency

For Claude CLI:
> Exact remaining Claude subscription tokens are unavailable unless Claude CLI exposes
> them officially. Showing estimated usage only.

## Architecture

```
lib/
  main.dart          — App entry, SharedPreferences + ApiClient initialization
  app.dart           — Router, MaterialApp, bottom navigation shell

  core/
    api/             — ApiClient (Dio), endpoints, exceptions, Riverpod providers
    config/          — AppConfig (defaults, limits)
    models/          — All data models (Session, Approval, Question, etc.)
    storage/         — SettingsStorage (SharedPreferences + FlutterSecureStorage)
    theme/           — AppTheme (dark, professional, electric blue/cyan/violet)
    widgets/         — Shared widgets (StatusBadge, MetricCard, EmptyState, etc.)

  features/
    onboarding/      — Server setup screen
    dashboard/       — Dashboard with metrics and quick actions
    sessions/        — Sessions list, detail, create, smart wizard
    conversation/    — Full timeline with composer
    approvals/       — Pending and resolved approvals
    questions/       — AI questions waiting for input
    proof/           — Proof packages and evidence
    tokens/          — Token usage and efficiency
    providers/       — Provider status (no secrets shown)
    computer_actions/ — Browser/computer action audit trail
    screenshots/     — Screenshot gallery
    ui_tests/        — UI test runner
    settings/        — Server URL, token, refresh interval
```

## Security Notes

See [SECURITY.md](SECURITY.md) for full security details.

## API Contract

See [API_CONTRACT_NOTES.md](API_CONTRACT_NOTES.md) for endpoint documentation.

## Implementation Plan

See [MOBILE_APP_PLAN.md](MOBILE_APP_PLAN.md) for architecture decisions and roadmap.
