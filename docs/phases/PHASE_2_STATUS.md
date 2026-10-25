# Phase 2 — Adaptive design and navigation foundation

**Status:** IN PROGRESS. The local UI foundation and responsive shell are implemented. Widget and iOS/macOS integration smoke tests now run on local targets. Android and Windows target verification remains in progress.

## Implemented

- CSC brand palette, Poppins typography (licensed OFL font files), CSC mark, and Material 3 theme.
- Adaptive phone navigation, iOS tab treatment, and tablet/desktop navigation rail with keyboard shortcuts.
- Branded home/preview screen and honest community section routes that hand off to current website pages while their native integrations are not yet implemented.
- Responsive phone and desktop widget coverage; the desktop layout scrolls without unbounded-height errors.
- Platform application labels and Apple bundle IDs use development identifiers. Android package namespace remains Java-compatible. Store publisher identity is not asserted.

## Verification

- `flutter analyze`: PASS — no issues found after font and bundle-ID updates.
- `flutter test --reporter expanded`: PASS — 2 widget tests.
- `flutter build macos --debug`: PASS — `build/macos/Build/Products/Debug/CSC Circle.app`.
- `flutter build ios --debug --no-codesign`: PASS — `build/ios/iphoneos/Runner.app`; compile only, not installed or run on a device.
- `flutter build ios --debug --simulator --no-codesign`: PASS — `build/ios/iphonesimulator/Runner.app`.
- `flutter test integration_test/app_smoke_test.dart -d <iPhone 17 simulator>`: PASS — launches the app and navigates to Discover.
- `flutter test integration_test/app_smoke_test.dart -d macos`: PASS — launches the macOS app and navigates to Discover.
- Android SDK platform/build tools/NDK/emulator installed; APK build and system image installation are in progress.
- GitHub Actions Windows build-and-test workflow added; remote run pending first push.
- `git diff --check`: PASS.

## Remaining Phase 2 gate

- Review light/dark, text scaling, contrast, keyboard focus, VoiceOver/TalkBack semantics, reduced motion and platform safe areas on actual device runtimes.
- Verify real native Liquid Glass treatment only if a supported bridge is justified; current Flutter surfaces are platform-adaptive but are not claimed to be native Liquid Glass.
- Add designed motion foundations and wider screen coverage before marking this phase complete.

## Limits

- iOS 26.4 simulator is verified. Xcode 27.1 runtime download stalled at 0 bytes, so testing used the already installed 26.4 runtime. Android SDK is installed; emulator image and APK compile are still pending. Windows build executes on GitHub after the initial push.
- Current source uses a public preview when no configured backend exists. No production members, events, or other live content are fabricated.
