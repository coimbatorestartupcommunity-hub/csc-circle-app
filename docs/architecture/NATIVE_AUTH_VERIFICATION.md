# Native authentication release verification

**Status:** Preparation only. No real CSC login, callback exchange, or test identity has been used.

## Current native configuration observed in source

| Platform | Current application identifier | Callback registration |
|---|---|---|
| iOS | `dev.cscircle.csc-circle-app` | `cscircle` URL scheme in `ios/Runner/Info.plist` |
| Android | `dev.cscircle.csc_circle_app` | `cscircle` scheme and `auth-callback` host in `android/app/src/main/AndroidManifest.xml` |
| macOS | `dev.cscircle.csc-circle-app` | `cscircle` URL scheme in `macos/Runner/Info.plist` |
| Windows | No package identity/AUMID assigned; executable product is `CSC Circle.exe` and file metadata uses `CompanyName=dev.cscircle` | No `cscircle` protocol registration found in the Windows runner |

These are the identifiers currently configured in the repository; CSC must confirm they are the final production IDs and match the identifiers registered with Apple/Google and any Supabase provider configuration. Do not silently change them. If CSC approves a different ID, update the native target/package/namespace and signing records together, then rebuild and test secure-storage access, callbacks, upgrades, and app links. Windows needs an explicit package identity and a protocol-handling decision before native callback authentication can be claimed. The exact proposed redirect is `cscircle://auth-callback`; its production allowlist status remains unverified.

## Registration preparation (do not change IDs until CSC confirms)

- **Apple:** in the CSC Apple Developer team, register/confirm the iOS and macOS bundle IDs and capabilities. Confirm the iOS and macOS targets use the approved IDs, then create or match the corresponding App Store Connect app records and distribution profiles. The `cscircle` scheme is a URL type in both app plists; verify it remains registered in the signed builds.
- **Google Play:** register/confirm the exact Android application ID in Play Console. Match it to `applicationId` in `android/app/build.gradle.kts` and the Kotlin namespace/package; preserve the custom callback intent filter. Configure the owner-controlled upload key and Play App Signing before creating a release artifact.
- **Supabase:** add the exact `cscircle://auth-callback` to Authentication → URL Configuration → Redirect URLs after CSC approves it. Provider-specific credentials stay in provider/Supabase server configuration. Bundle/package IDs do not substitute for the redirect allowlist.
- **Windows:** select a distribution format (for example, MSIX or an approved installer), then assign an owner-approved package identity, publisher identity, AUMID and signing certificate. Decide whether Windows native Auth callbacks are supported; if yes, add and test an OS protocol handler before enabling callback-based features.
- Record each approved ID, team/tenant owner, signing owner, callback, environment and build channel in CSC’s release record. Keep development/test IDs separate from production if CSC chooses that policy.

## Owner/operator verification steps

1. With authorized Supabase dashboard access, record the enabled Auth providers and CSC-approved sign-in methods. For each OAuth provider, check the provider's client/application IDs and secret configuration server-side; never copy secrets into Flutter, source control, build logs, or a public issue.
2. In Supabase Authentication URL Configuration, confirm the exact `cscircle://auth-callback` redirect is allowlisted. Confirm any site URL and email templates use the approved redirect. Do not set `CSC_AUTH_REDIRECT_APPROVED=true` until this exact URI is saved and verified.
3. Confirm the three current native identifiers above against the final registered app IDs and signing configuration. Record any approved changes before release builds.
4. Obtain explicit approval for one isolated test identity, a second test identity for cross-user denial tests, and the permitted operation scope. Confirm signup/auth triggers and email side effects before creating either identity.
5. With those identities, verify provider sign-in, PKCE code exchange through the OS callback, persisted session after force-close/relaunch, token refresh, expiry behavior, logout/revocation, and callback replay/error handling on iOS, Android, and macOS. Then run owner-positive, anonymous-negative, and cross-user-negative read checks under real RLS.
6. Keep signup and recovery gated until step 2 and callback exchange pass. Keep member reads disabled until step 5 passes for the exact repositories and selected fields. No writes are enabled by these read tests.

## Existing fixture coverage and its limits

- Widget fixtures cover sign-in success, signup confirmation state, signup/recovery redirect gating, recovery-link-to-new-password UI, session-expiry transition, logout, and rendering an initially restored signed-in snapshot.
- Member dashboard fixtures cover all five sections, masking of the member ID, logout state removal, and replacement of user-scoped state when the auth user changes.
- Storage unit fixtures verify session JSON and PKCE verifier use separate secure-storage keys. `main.dart` configures PKCE plus secure session and verifier stores.
- These fixtures do not prove Supabase accepted a real provider, callback exchange, Keychain/Keystore persistence across process restart, token refresh/revocation, or backend RLS. OS callback routing was previously smoke-checked on iOS Simulator and Android only. Those real checks require approved identities and settings.
