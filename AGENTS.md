# ScamShield Mobile Development Guidelines

ScamShield Mobile is a Flutter app for Android and iOS. Its Dart package name is `scamshield_mobile`.

## Project Structure

- `lib/app/` configures the app, its theme, and app-level navigation.
- `lib/core/` contains the theme and components shared across the app.
- `lib/ui/<feature>/` contains feature-specific screens, widgets, and state. Place widgets used by multiple features in `lib/ui/shared/`.
- `lib/data/` contains models, repositories, and services. When integrating a backend, make API calls in services and access data through repositories.
- Use `setState` for local UI state, such as the selected tab. Use Provider with a ViewModel when several widgets share state or a feature coordinates asynchronous data.

## Flutter UI

- Keep screens focused on layout and navigation. Extract parts with distinct responsibilities, such as forms, warning lists, and menus, into separate widgets. Reuse existing widgets where appropriate.
- Keep input validation and business logic outside widgets so they can be tested independently. Release controllers created by a widget in its `dispose` method.
- Use `AppTheme` for shared colors and styles. When adapting the web UI, check the web source and preserve ScamShield VN's navy, blue, and light purple-gray palette. Avoid green in the UI.
- Write labels and messages in Vietnamese with diacritics. When changing a form, check its layout on narrow screens and with the keyboard open.
- Show risk assessments only when the analysis service provides a result. Input validation confirms only that the data is in a valid format.

## Verification

- Use `snake_case` for Dart filenames, `UpperCamelCase` for types, and `lowerCamelCase` for variables and functions. Keep changes within the scope of the request.
- For Dart changes, run `dart format` on modified files and run `flutter analyze`. Run the relevant tests in `test/` when behavior changes.
- For UI changes, check the result on an emulator or device if available. Report any checks you could not run or results you could not verify.
