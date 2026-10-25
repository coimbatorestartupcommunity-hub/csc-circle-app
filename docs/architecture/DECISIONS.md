# Architecture decisions

## 2026-10-25 — Flutter as the shared client foundation

The implementation prompt selects Flutter for cross-platform mobile and desktop. A development namespace is used pending confirmation of legal publisher/store ownership. Windows packaging will run on Windows CI/host.

## 2026-10-25 — Keep Supabase and the website as the shared source of truth

The website already uses Supabase Auth/Postgres/Storage, and has RLS plus transaction RPCs. The app will use Supabase Auth and safe published/owner-scoped Data API operations; it will not create a second account or member database or embed privileged credentials.

## 2026-10-25 — Do not reuse cookie-backed website handlers in the app

The existing Next.js server client is cookie-bound. The native app will use bearer JWTs through Supabase Flutter. Any complex workflow lacking a safe table/RPC contract needs a separately reviewed mobile API on the website repository.

## 2026-10-25 — Defer admin mobile tools and live account deletion until contracts exist

Admin flows depend on server-only permissions and service-role operations. A member-facing account deletion workflow was not found in inspected source. Neither should be simulated in the app.
