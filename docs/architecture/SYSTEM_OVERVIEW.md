# System overview

CSC Circle mobile clients use Flutter for shared domain and presentation code with platform-adaptive navigation and controls. The existing Next.js website remains the CMS and canonical web fallback. Supabase remains the single source of truth for Auth, memberships, profiles, events, notifications, and published content.

The only client-side Supabase credential is the public project URL and publishable key. The Supabase Auth access token accompanies direct Data API/RPC requests; row-level security and invoker RPC checks decide access. No server key or website cookie is copied into the app.

```text
Flutter app (iOS/iPadOS, Android, macOS, Windows)
    ├── Supabase Auth (PKCE / platform deep link)
    ├── Supabase Data API + verified invoker RPCs (RLS enforced)
    └── CSC website routes for public/private media and web-only workflows
             └── Supabase Auth, Postgres/RLS, private Storage
```

API contract definitions live in the app behind typed feature repositories. Direct tables are used only where published/owner-scoped RLS is verified. Business workflows use existing SQL RPCs where available. Complex server workflows without a proven mobile boundary remain out of scope until reviewed endpoints are added in a separate website branch.
