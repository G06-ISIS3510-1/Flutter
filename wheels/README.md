# wheels

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

### Run the app

```bash
flutter pub get
flutter run
```

### Architecture (Feature-First + Clean)

The app uses a pragmatic Feature-First Clean Architecture under `lib/`:

- `app/`: App bootstrap (`WheelsApp`) and root setup.
- `router/`: go_router route constants and full route mapping.
- `theme/`: App tokens (`app_colors`, `app_spacing`) and `app_theme`.
- `shared/`: Reusable UI (`AppScaffold`), widgets (`AppButton`), and utils.
- `features/`: Vertical feature modules (`auth`, `rides`, `payments`, etc.) with:
  - `presentation/` (screens, providers, widgets)
  - `domain/` (entities, repository contracts)
  - `data/` (models, datasources, repository implementations)

Router is configured with 13 routes and Riverpod provider stubs per feature for Sprint 1 scaffolding.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
