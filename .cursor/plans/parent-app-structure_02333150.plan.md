---
name: parent-app-structure
overview: Restructure lib and scaffold full feature/BLoC architecture per SRS without mock data.
todos:
  - id: core-setup
    content: Create core layer (routing, dio, storage, theme hooks)
    status: completed
  - id: features-scaffold
    content: Scaffold feature folders (data/domain/presentation) per SRS
    status: completed
  - id: screens-stub
    content: Add minimal screens/widgets for all listed features
    status: in_progress
  - id: app-wire
    content: Wire routing/providers to new screens
    status: pending
  - id: hooks-docs
    content: Document TODO hooks for APIs/FCM/maps/storage
    status: pending
  - id: todo-1765465725862-5pqk450ta
    content: ""
    status: pending
---

# Parent App Restructure & Scaffolds

## Steps

1) **Define core layer**: create `lib/core/` (config, routing, theme, localization hooks, dio client + interceptors, storage helpers, error/result types). Wire existing `AppController`/theme pieces into `core` where appropriate without changing behavior.
2) **Feature directories**: under `lib/features/` create folders for `auth`, `language`, `dashboard`, `tracking`, `students`, `absence`, `notifications`, `communication`, `complaints`, `profile`. Each feature gets `data/` (repo interfaces, DTOs, endpoints placeholders), `domain/` (entities, usecases stubs), `presentation/` (bloc/cubit stubs + views).
3) **Screen stubs**: create minimal screens/widgets per SRS (login, language selector, dashboard, child list/detail, live tracking, absence request/history, notifications, chat/communication, complaint form, profile/settings, add child, about/contact). Keep UI lightweight; no mock data—just layout placeholders/TODOs and dependency hooks.
4) **App shell wiring**: update `main.dart`/`app.dart` to use the new routing/navigation, register blocs/providers, and point entry routes to the new screens; keep existing splash/login flow intact but migrate to new structure.
5) **Integration hooks**: add TODOs for API calls (LOGIN, GET_STUDENTS, GET_BUS_LOCATION, etc.), FCM topics, map providers, storage keys; include contracts in repos and comments for expected request/response shapes.
6) **Consistency pass**: ensure RTL/language support switches are present, icons unified (Phosphor/Remix), and reusable UI components placed under `core/ui/` or shared widgets.