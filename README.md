Free Family Tree Maker

A calm, offline-first Flutter family tree app. The current foundation includes:

- multiple local family trees
- create, rename, and delete trees
- people profiles with biographies, notes, dates, and places
- parent, child, and partner relationships with cycle and duplicate protection
- deterministic multi-generation tree layout with pan and pinch zoom
- clipboard backup and restore as a versioned JSON family-tree format
- SQLite persistence
- Riverpod state management
- go_router navigation
- analyzer, repository, relationship, layout, and backup tests

To build & run:
1. Install Flutter: https://flutter.dev/docs/get-started/install
2. Open terminal in this project folder
3. Run: flutter pub get
4. Launch on an emulator or device: flutter run
5. Build APK: flutter build apk --release

Notes:
- Local-only app: all data stays on device in SQLite.
- Backups can be copied to the clipboard from a tree's More tab and restored as a new tree.
- CI builds the APK and runs analysis/tests in GitHub Actions.
