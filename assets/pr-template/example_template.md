## What

Add JWT refresh token endpoint so users stay logged in without re-entering credentials.

## Why

Ticket: PROJ-42 — Sessions expire after 1 hour causing users to be logged out mid-workflow.
Plan: `docs/jwt-refresh_2026-07-25.md`

## How

Added `POST /auth/refresh` endpoint that validates an existing refresh token (stored in HttpOnly cookie), issues a new access token (15 min TTL), and rotates the refresh token on each use to prevent replay attacks.

## Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Refresh token replay if response intercepted | Low | High | Token rotation — old token invalidated on use |
| Cookie not sent on cross-origin requests | Medium | Medium | Verified `SameSite=Strict` + CORS config in staging |

## Test Coverage

- Unit: `RefreshTokenService` — valid token, expired token, already-used token
- Integration: `POST /auth/refresh` — 200 with new tokens, 401 on invalid, 401 on reuse
- Manual: verified cookie flow in browser on staging env

## Architecture Review

SA review run — no must-fix items.
- **Should fix (deferred):** Extract token rotation into a separate `TokenRotationPolicy` class (logged as PROJ-45)

## Implementation Steps

1. Added `refresh_tokens` table migration with `token_hash`, `user_id`, `expires_at`, `used_at`
2. Implemented `RefreshTokenService.rotate()` — validates, marks used, issues new pair
3. Added `POST /auth/refresh` route with HttpOnly cookie read
4. Wired rate limiting (5 req/min per IP) via existing `RateLimiter` middleware
5. Updated auth integration tests

## Checklist

- [x] Matches plan scope (PROJ-42)
- [x] Build and lint pass
- [x] Tests pass
- [x] Risks documented
- [x] No unintended side effects
- [x] Ready for review

---

**Claude session:** sess_01ABCxyz123
