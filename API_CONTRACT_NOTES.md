# API Contract Notes — Eternal Shift Mobile

## Base URL

Configurable by user. Default: `http://127.0.0.1:8765`

## Authentication

All requests include:
```http
Authorization: Bearer <token>
```

## Response Format

### Success
```json
{
  "ok": true,
  "data": {},
  "message": "Optional message"
}
```

### Error
```json
{
  "ok": false,
  "error": {
    "code": "SESSION_BLOCKED",
    "message": "Session is blocked waiting for approval.",
    "details": {}
  }
}
```

## Error Codes

| Code | Meaning | App Behavior |
|------|---------|-------------|
| `UNAUTHORIZED` | Invalid token | Redirect to settings |
| `SESSION_BLOCKED` | Session needs attention | Show blocked panel |
| `PROVIDER_UNAVAILABLE` | AI provider not configured | Show provider error |
| `TOKEN_BUDGET_EXCEEDED` | Token limit reached | Show token warning |
| `RISK_POLICY_BLOCKED` | Safety policy blocked action | Show safety warning |
| `INTERNAL_ERROR` | Server error | Show friendly error |
| `SERVER_UNAVAILABLE` | Cannot connect | Show offline state |

## Mobile-Specific Endpoints

```
GET /api/v1/mobile/home       — Dashboard summary
GET /api/v1/mobile/attention  — Items needing human attention
```

These are designed for efficient mobile polling.

## Polling Strategy

The app polls `/api/v1/mobile/home` and `/api/v1/mobile/attention` every N seconds
(configurable in Settings, default 8s).

SSE event streams (`/api/v1/events/stream`) are not implemented in v1.
Polling is used instead to avoid battery drain.

## Key Endpoints

### System
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/health` | Health check |
| GET | `/api/v1/system/status` | Full system status |
| GET | `/api/v1/mobile/home` | Mobile dashboard data |
| GET | `/api/v1/mobile/attention` | Items needing attention |

### Sessions
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/sessions` | List sessions |
| POST | `/api/v1/sessions` | Create session |
| GET | `/api/v1/sessions/{id}` | Get session |
| PATCH | `/api/v1/sessions/{id}` | Update session |
| POST | `/api/v1/sessions/{id}/pause` | Pause |
| POST | `/api/v1/sessions/{id}/resume` | Resume |
| POST | `/api/v1/sessions/{id}/stop` | Stop |
| POST | `/api/v1/sessions/{id}/reopen` | Reopen |
| DELETE | `/api/v1/sessions/{id}` | Soft-delete |

### Smart Sessions
| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/v1/input/analyze` | Analyze goal text |
| POST | `/api/v1/sessions/smart-create` | Create from analysis |
| POST | `/api/v1/sessions/smart-create-and-run` | Create and run |

### Cycles
| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/v1/sessions/{id}/run-cycle` | Run one cycle |
| POST | `/api/v1/sessions/{id}/run-until-approved` | Run until approved (requires `max_cycles`) |
| POST | `/api/v1/sessions/{id}/stop-after-current-cycle` | Stop after current |

### Messages / Conversation
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/sessions/{id}/conversation` | Full timeline |
| POST | `/api/v1/sessions/{id}/messages` | Post message |
| POST | `/api/v1/sessions/{id}/notes` | Add note |
| POST | `/api/v1/sessions/{id}/feedback` | Send feedback |

Message body:
```json
{
  "content": "string",
  "type": "note|comment|feedback|answer|important_note|dismissal",
  "target_role": "worker|reviewer|supervisor|system"
}
```

### Approvals
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/approvals` | All approvals |
| POST | `/api/v1/approvals/{id}/approve` | Approve (does not execute instantly) |
| POST | `/api/v1/approvals/{id}/reject` | Reject |
| POST | `/api/v1/approvals/{id}/dismiss` | Dismiss |

Approve/reject body:
```json
{"comment": "Optional comment"}
```

### Questions
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/questions` | All questions |
| POST | `/api/v1/questions/{id}/answer` | Answer |
| POST | `/api/v1/questions/{id}/dismiss` | Dismiss (non-critical only) |

### Tokens
All token endpoints may return `is_estimated: true` when using Claude CLI.
The app displays a disclosure notice in this case.

### Providers
Provider credentials are never returned by any endpoint.
The app only shows: name, available, mode, model, timeout, error.
