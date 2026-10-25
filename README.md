# CSC Circle

Native app for Coimbatore Startup Community. The app uses the existing CSC Circle identity and Supabase project; it does not create a second member database.

## Local setup

Flutter is installed per developer machine. Use the stable Flutter channel with the Dart version recorded in [`docs/architecture/toolchains.md`](docs/architecture/toolchains.md).

```sh
flutter pub get
flutter analyze
flutter test
flutter run -d <device-id>
```

Configure only the public Supabase project URL and publishable key with `--dart-define` or a local, gitignored `dart_defines.json` file. Copy `dart_defines.example.json` to `dart_defines.json` and fill the values from the authorized project settings. Never put a Supabase secret/service-role key, user export, signing key, or session token in this repository or app binary.

```sh
flutter run --dart-define-from-file=dart_defines.json
```

The checked-in application identifiers are temporary development identifiers. Store publisher ownership and final bundle/package IDs need owner review before signing or publication.

## Platform status

See [`docs/phases/PHASE_1_STATUS.md`](docs/phases/PHASE_1_STATUS.md), [`docs/phases/PHASE_2_STATUS.md`](docs/phases/PHASE_2_STATUS.md), and [`docs/architecture/toolchains.md`](docs/architecture/toolchains.md) for verified setup, findings, gates, and platform state. Windows packages require Windows CI or a Windows host. Store signing and publication are separate owner-controlled actions.
