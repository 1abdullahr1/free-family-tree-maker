Free Family Tree Maker

A calm, offline-first Flutter family tree app foundation. Milestone 1 includes:

- multiple local family trees
- create, rename, and delete trees
- SQLite persistence
- Riverpod state management
- go_router navigation
- a tree workspace shell ready for later milestones

To build & run:
1. Install Flutter: https://flutter.dev/docs/get-started/install
2. Open terminal in this project folder
3. Run: flutter pub get
4. Launch on an emulator or device: flutter run
5. Build APK: flutter build apk --release

Notes:
- Local-only app: all data stays on device in SQLite.
- CI builds the APK and runs analysis/tests in GitHub Actions.
