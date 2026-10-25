# Phase 2 — Adaptive design and navigation foundation

**Status:** IN PROGRESS. The responsive shell, design foundation, and smoke coverage are implemented. Remaining accessibility, visual adaptation, and motion review still gate phase completion.

## Implemented

- CSC palette, licensed Poppins typography, official CSC mark, and Material 3 theme.
- Adaptive phone navigation, iOS tab treatment, tablet/desktop navigation rail, and keyboard shortcuts.
- Branded public preview and community-section routes that hand off to current website pages while native integrations are not ready.
- Responsive phone and desktop widget coverage.
- Reproducible official app-icon generation for Apple, Android, and Windows targets via [`scripts/generate_app_icons.sh`](../../scripts/generate_app_icons.sh).
- Temporary development identifiers; publisher ownership is not asserted.

## Verification

- `flutter analyze`: PASS.
- `flutter test --reporter expanded`: PASS — 4 widget tests, including all five phone destinations and a compact 320 px layout at 2× text scaling.
- Xcode MCP: connected to `ios/Runner.xcworkspace`; `Runner` scheme and iPhone 17 (iOS 26.4.1) destination selected. Xcode build passed (144 seconds).
- iPhone 17 simulator: CSC Circle installed and launched. The visible first screen is the public home preview.
- `flutter build macos --debug`: PASS.
- `flutter build ios --debug --no-codesign`: PASS (compile only).
- `flutter build ios --debug --simulator --no-codesign`: PASS.
- iOS 26.4.1 iPhone 17 simulator integration test: PASS — opens home and navigates to Discover.
- macOS integration test: PASS — opens home and navigates to Discover.
- Android API 36 emulator integration test: PASS — opens home and navigates to Discover. Debug APK build passed (197 MB).
- GitHub Windows runner: PASS — `flutter analyze`, widget tests, Windows release build, and unsigned artifact upload in [run 40220477021](https://github.com/coimbatorestartupcommunity-hub/csc-circle-app/actions/runs/40220477021).
- `git diff --check`: PASS on the initial implementation commit; rerun after this update.

## Evidence

- [iOS iPhone 17 home](../evidence/ios26-iphone17-home.png)
- [iOS iPhone 17 Discover](../evidence/ios26-iphone17-discover.png)
- [Android API 36 Discover](../evidence/android36-emulator-discover.png)
- Windows build logs and artifact: [GitHub Actions run](https://github.com/coimbatorestartupcommunity-hub/csc-circle-app/actions/runs/40220477021)

## Remaining phase gate

- Review light/dark themes, text scaling, contrast, keyboard focus, VoiceOver/TalkBack semantics, reduced motion, and platform safe areas on supported runtimes.
- Add designed motion foundations and wider tablet/desktop coverage.
- The app is platform-adaptive; Flutter surfaces are not claimed to be native Liquid Glass.
- First-launch onboarding and an introductory animation are not implemented, so they cannot yet be verified.
- Xcode MCP device interaction requires iOS 27.0 or newer and is unavailable on the installed iOS 26.4.1 simulator; the app was launched with CoreSimulator tools instead.
- Xcode live indexing reported `No such module 'Flutter'` and an initial dependency graph response failure. The later Xcode build completed successfully; no Flutter/Dart or native source repair was needed.
- Apple and Android targets rebuilt after icon asset replacement; Windows CI verified the generated Windows icon in [run 40224308612](https://github.com/coimbatorestartupcommunity-hub/csc-circle-app/actions/runs/40224308612). The test update passed Windows CI in [run 40226004254](https://github.com/coimbatorestartupcommunity-hub/csc-circle-app/actions/runs/40226004254).

## Limits

- Xcode 27.1's iOS 27.1 simulator runtime download stalled at 0 bytes. iOS 26.4.1 is installed and tested.
- Current source uses a public preview without a configured backend. It does not fabricate member/event content.
- Windows output is unsigned and was built on a hosted Windows runner. Interactive launch, MSIX packaging, signing, and store verification are not complete.
