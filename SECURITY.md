# Security — Eternal Shift Mobile

## Architecture Safety

The mobile app is a **pure API client**. It:

- Does NOT run any LLM locally
- Does NOT access the server database directly
- Does NOT execute shell commands
- Does NOT run Claude or any AI model on-device
- Only calls `/api/v1` endpoints on the Eternal Shift server

The server remains the single source of truth for all orchestration, sessions,
approvals, and decisions.

## Token Storage

API tokens are stored using `flutter_secure_storage`:
- Android: AES encrypted via EncryptedSharedPreferences
- iOS: Keychain Services

The token is **never displayed** after saving. The app shows only masked token state.
To update the token, go to Settings and enter a new value.

## Secrets Policy

- API tokens are not hardcoded anywhere in the app
- No secrets are shipped with the app
- Provider credentials (Anthropic API keys, etc.) are never requested by the mobile app —
  they must be configured on the server

## Approval Safety

Approvals on the mobile app do **not** execute actions instantly.

When you approve a request:
1. The app sends `POST /api/v1/approvals/{id}/approve` to the server
2. The server marks the approval as approved
3. The next safe server-side cycle reads this approval and decides whether to continue

This means dangerous actions (file deletion, shell commands, API calls) are never
triggered directly from the mobile app.

## Dangerous Action Confirmation

The following actions require explicit confirmation dialogs before proceeding:
- Stop session
- Delete session
- Approve a sensitive request
- Run a cycle with a real provider (shows token consumption warning)
- Run until approved (requires max cycle limit — infinite runs not allowed)
- Change server URL
- Change API token
- Clear API token

## No Infinite Runs

`run-until-approved` always requires a `max_cycles` parameter.
The app enforces a maximum of 50 cycles per run-until-approved call.
Infinite background loops are not permitted.

## Token Usage Transparency

For Claude CLI:
> Exact remaining Claude subscription tokens are unavailable unless Claude CLI
> exposes them officially. Showing estimated usage only.

The app never fabricates remaining token values.

## Server Exposure Risks

- **Do not** expose your Eternal Shift server to the public internet without authentication
- On LAN, anyone on the same network who knows your server IP and token can control it
- Use a VPN or firewall rules if you need remote access outside your home network
- The server's own authentication (`Authorization: Bearer <token>`) is the primary gate

## Error Handling

Raw server stack traces are never shown to the user.
All API errors are mapped to friendly user messages.
