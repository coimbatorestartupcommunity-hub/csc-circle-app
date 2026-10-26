# CSC Circle native release readiness

**Status:** Not release-ready. This is a preparation checklist; no store submission or production release was made.

## App identity and signing

- [ ] CSC confirms final production IDs. Current repository values and the Windows gap are recorded in [`NATIVE_AUTH_VERIFICATION.md`](NATIVE_AUTH_VERIFICATION.md); do not change them without approval.
- [ ] **iOS:** register the approved bundle ID with the CSC Apple Developer team; configure team, distribution certificate, App Store provisioning, capabilities, URL scheme, version/build number, and archive/export validation. Current Xcode project uses automatic signing but has no `DEVELOPMENT_TEAM` value; simulator verification is not distribution signing.
- [ ] **Android:** register the approved `applicationId` in Play Console and approve the upload/app-signing ownership. Replace the current release build's debug-key signing with a protected upload keystore from CI secrets; verify key rotation/recovery ownership and a signed release artifact.
- [ ] **macOS:** approve bundle ID and distribution channel. Configure Developer ID/App Store signing identity, provisioning/entitlements, hardened runtime, notarization/stapling for direct distribution or the approved Mac App Store archive path. Current local debug launch does not verify distribution signing.
- [ ] **Windows:** choose and register a package identity/AUMID, publisher, certificate, and distribution channel. Current Flutter runner has product metadata (`CSC Circle`) but no MSIX/package identity or configured signing; GitHub Actions uploads an unsigned artifact.
- [ ] Confirm display name, icons, marketing version and build numbering across platforms. Current `pubspec.yaml` is `1.0.0+1`; establish the approved release version and update cadence.

## Authentication and security

- [ ] Complete [`NATIVE_AUTH_VERIFICATION.md`](NATIVE_AUTH_VERIFICATION.md): approved providers, exact redirect allowlist, final identifiers, isolated identities, real callback/PKCE exchange, secure session restore, refresh/expiry, logout/revocation, and platform coverage.
- [ ] Keep signup/recovery disabled until the authorized callback exchange succeeds. Do not enable member reads until positive owner and anonymous/cross-user denial checks pass for every intended query/RPC.
- [ ] Review RLS contracts and selected columns with the server owner; test missing membership, expired session, account switch and permission failures.
- [ ] Keep all writes disabled until their individual server/RPC contracts and disposable test cases are approved.
- [ ] Review the staged Resources view and website/native rollout in [`proposals/RESOURCES_PUBLIC_PROJECTION.md`](proposals/RESOURCES_PUBLIC_PROJECTION.md). Retain the base grants until the supported-version migration plan is approved and both clients are ready.
- [ ] Review storage exposure, key handling, crash/log redaction, transport/offline errors and secure-storage behavior on signed distribution builds.

## Privacy, deletion and store materials

- [ ] CSC approves the record-by-record retention/deletion matrix, timing/cancellation rules, identity verification, holds/support path, endpoint contract, retries, audit behavior and negative authorization tests in [`ACCOUNT_DELETION_DESIGN.md`](ACCOUNT_DELETION_DESIGN.md).
- [ ] Publish and approve privacy policy, account-deletion instructions/URL, support contact, data collection/use disclosures, platform privacy declarations, screenshots and store descriptions. Ensure disclosures match actual analytics, storage, notifications, media and Auth behavior.
- [ ] Confirm accessibility, age/content ratings, regional availability, legal notices, customer support and data-subject request procedures with the responsible CSC owner.
- [ ] Test the deletion workflow end-to-end using an approved isolated identity before offering it to members; no production deletion test without explicit approval.

## Quality, rollout and recovery

- [ ] Complete Flutter unit/widget/integration tests and signed iOS, Android, macOS and Windows release-candidate checks. Run VoiceOver/TalkBack/keyboard/focus/text scaling and reduced-motion checks on actual platform builds.
- [ ] Verify app startup, session restore, callback, sign-out, offline/retry, screen transitions, low-memory/resume, and notification/deep-link behavior in distribution-signed builds.
- [ ] Approve the minimum supported app version and force-update/sunset strategy before any backend contract or Resources privilege change that affects older binaries.
- [ ] Define staged rollout, monitoring/alert ownership, crash reporting, rollback build availability, support escalation and incident communications.
- [ ] Obtain CSC release approval after the checklist evidence is reviewed. Do not submit to app stores before that approval.
