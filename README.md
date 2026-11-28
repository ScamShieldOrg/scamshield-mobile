# ScamShield Mobile

Flutter app for Android and iOS. The Dart package name is `scamshield_mobile`.

## Running the App

Use a Flutter SDK that includes Dart 3.12 or later. Start an Android emulator or connect a device, then run the following commands from the project root.

```powershell
flutter pub get
flutter run
```

To run the iOS app, use macOS with Xcode installed. Run `flutter analyze` for static analysis and `flutter test` for tests.

Set `API_BASE_URL` in the project-root `.env` file, for example `API_BASE_URL=https://your-backend.example/api`. Leave it empty to use the platform's local debug address. Profile and release builds require a URL. A nonempty `--dart-define=API_BASE_URL=...` overrides the file. Stop and rerun the app after changing `.env`. Keep secrets out of the file because Flutter bundles it with the app.

## Project Structure

| Directory | Purpose |
| --- | --- |
| `lib/app/` | Root widget and app configuration |
| `lib/core/theme/` | Shared theme |
| `lib/data/models/` | App data types |
| `lib/data/services/` | API calls and local data access |
| `lib/data/repositories/` | Data access for ViewModels |
| `lib/ui/home/` | Home screen |
| `lib/ui/shared/` | Widgets shared across features |

Each feature has its own directory under `lib/ui/`. When a screen needs a ViewModel to manage its state, place the `*_viewmodel.dart` file next to the screen and use Provider to expose the ViewModel to its widgets.
