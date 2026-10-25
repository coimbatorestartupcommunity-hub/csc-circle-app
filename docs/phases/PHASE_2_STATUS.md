# Phase 2 — Adaptive design and navigation foundation

**Status:** COMPLETE — acceptance evidence and Windows CI are recorded in [PHASE_2_COMPLETE.md](PHASE_2_COMPLETE.md). Phase 3 backend audit is now underway.

## Implemented

- Added a first-run, three-step CSC Circle introduction with branded reveal animation, page progress, explicit public-preview messaging, Skip, and locally persisted completion.
- Added saved system/light/dark appearance and reduced-motion preferences. A bounded preference-load fallback prevents a slow local store from holding the user on the launch view indefinitely.
- Added semantic color roles and light/dark themes; responsive iOS/macOS Cupertino controls and restrained translucent navigation, Android Material 3 navigation, and Windows/desktop Material adaptations.
- Added keyboard destination shortcuts, visible focus behavior, screen-reader labels, larger-text scrolling, high-contrast blur fallback, and responsive layouts.
- Downsampled cached brand imagery in the UI. Motion is limited to an 820 ms logo reveal and short page transition; there are no continuous animations or full-screen backdrop blurs.
- Added phone onboarding and wide-desktop golden screenshots, expanded widget coverage, and a first-launch/navigation/persistence integration smoke test.

## Local verification

- `flutter analyze`: PASS — no issues.
- `flutter test --reporter expanded`: PASS — 19 widget tests, including 2 golden tests.
- Windows CI revealed expected host-font rasterization differences in the two image goldens. Those pixel comparisons now skip on Windows; all onboarding, layout, accessibility, settings, and navigation behavior tests still run there.
- iPhone 17 / iOS 26.4.1: Xcode MCP `Runner` build PASS; Xcode build log has no errors; `Runner/AppDelegate.swift` diagnostics: 0. Flutter integration test PASS. Standalone first-run screen captured at [iOS onboarding](../evidence/ios26-iphone17-first-launch.png).
- Android API 36 emulator: debug APK build PASS; integration test PASS. TalkBack was enabled on the emulator and bound successfully. Its accessibility tree exposed the onboarding heading, page state, Skip, and Next controls; TalkBack text-to-speech generated navigation speech. TalkBack was disabled afterward.
- macOS: debug build and integration test PASS. The app was visible in the running macOS window and its navigation/content labels were inspectable. macOS VoiceOver was enabled for the accessibility check and restored to its previous off state afterward.
- Widget tests exercise reduced motion, light/dark selection, 2× text scale, keyboard shortcut/focus, semantics actions, all five navigation destinations, and widths from 320 through 1920 logical pixels.
- `git diff --check`: PASS.

## Screenshot and test evidence

- [Phone onboarding golden](../../test/goldens/phase2_onboarding_phone.png)
- [Desktop home golden](../../test/goldens/phase2_desktop_home.png)
- [iPhone 17 first launch](../evidence/ios26-iphone17-first-launch.png)
- [Android API 36 first launch](../evidence/android36-first-launch.png)
- Existing [iOS Home](../evidence/ios26-iphone17-home.png), [iOS Discover](../evidence/ios26-iphone17-discover.png), and [Android Discover](../evidence/android36-emulator-discover.png) captures remain preserved.

## Xcode diagnostics

The stale generated-file issues in the supplied Xcode screenshot were cleared by refreshing Flutter-generated iOS artifacts and rebuilding. The latest Xcode build succeeds with no errors and the app delegate has zero diagnostics. Remaining Xcode warnings are quoted-include warnings emitted by headers inside the generated Flutter framework; no app-owned source warnings were reported.

## Limitations carried forward

- Direct iOS VoiceOver focus movement was not exercised: the installed iOS simulator is 26.4.1 and Xcode MCP device interaction requires iOS 27 or newer. Flutter semantics are covered in tests, and VoiceOver was checked on the running macOS app. Keep this limitation visible in the completion report.
- No native Apple Liquid Glass bridge was added; the app uses supported Flutter Cupertino controls and restrained translucent materials. Do not describe this as native Liquid Glass.
- Performance audit found one finite 820 ms brand reveal, short page transitions, cached/downsampled local imagery, and no perpetual animations or full-screen blur. Automated responsive tests produced no layout exceptions at widths 320–1920. A profile-mode Android cold launch logged 119 skipped frames on its first frame; the emulator's `gfxinfo` did not expose Flutter surface frame data afterward, so a trustworthy cold-start/frame-time profile remains outstanding for later performance work.
- The app is still an honestly labeled public preview. Supabase authentication and live member data remain Phase 3 work; no production records were changed.
