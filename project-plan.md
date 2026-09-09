# Tamam — Open Source TickTick Alternative

## Full Project Plan

_Local-first, mobile-only (iOS/Android) MVP, built to support sync later without a rewrite._

---

## 1. Vision & Scope

An open-source, privacy-respecting task manager inspired by TickTick, built in Flutter. Phase 1 is fully local (no account, no server) with a data layer designed so a sync backend can be bolted on later without breaking the schema or rewriting the repository layer.

**Non-goals for v1:** multi-user collaboration, real-time sync, web/desktop builds, third-party calendar integration. All are explicitly deferred, not designed away.

---

## 2. Feature Set

### MVP (v1.0)

- Tasks: title, notes, due date/time, priority, subtasks, checklist items
- Projects/Lists with custom colors and icons
- Tags (many-to-many), with tag-based filtering
- Recurring tasks (RFC 5545 rules — daily/weekly/monthly/custom)
- Smart lists: Today, Next 7 Days, All, Completed, Flagged
- Calendar view (month/week) showing tasks by due date
- Local reminders/notifications (single + repeating)
- Drag-to-reorder tasks and subtasks
- Dark/light theme, Material 3
- Full offline functionality, zero network dependency

### v1.x (fast follows)

- Pomodoro timer tied to tasks (focus sessions logged per task)
- Habit tracking (separate from tasks — streaks, calendar heatmap)
- Search (full-text across tasks/notes)
- Widgets (home screen quick-add, today list)
- Backup/restore to local file (JSON/SQLite export) — this doubles as your sync migration path later
- Natural language quick-add ("Call mom tomorrow 5pm #family")

### v2.0+ (post local-only phase)

- Sync backend (revisit backend choice — see §7)
- Attachments (images/files on tasks)
- Multi-device support

---

## 3. Tech Stack Summary

| Layer                | Choice                                                                 | Why                                                                           |
| -------------------- | ---------------------------------------------------------------------- | ----------------------------------------------------------------------------- |
| Framework            | Flutter (stable channel)                                               | Given                                                                         |
| State management     | Riverpod + riverpod_generator                                          | Compile-safe, testable, pairs with Drift streams                              |
| Local database       | Drift (SQLite)                                                         | Relational model (tasks/subtasks/tags/projects), migrations, reactive streams |
| Routing              | go_router                                                              | Standard, deep-link ready, declarative                                        |
| Recurrence           | rrule                                                                  | RFC 5545 compliant, don't hand-roll this                                      |
| Notifications        | flutter_local_notifications + timezone                                 | Local scheduling, DST-safe                                                    |
| Calendar UI          | table_calendar                                                         | MIT licensed, lightweight, avoids Syncfusion licensing issues                 |
| Forms/validation     | reactive_forms or plain Riverpod state                                 | Keep it simple for v1                                                         |
| Dependency injection | Riverpod providers (no separate DI package needed)                     | Riverpod already covers this                                                  |
| Testing              | flutter_test, mocktail, integration_test                               | Standard trio                                                                 |
| Linting              | flutter_lints / very_good_analysis                                     | Consistent OSS code style                                                     |
| CI/CD                | GitHub Actions + Codemagic (free tier for iOS signing)                 | No Mac needed for OSS contributors                                            |
| Localization         | flutter_localizations + intl, slang or easy_localization               | Plan for i18n early if you want OSS contributors translating                  |
| Crash/analytics      | None by default, or self-hosted-only (e.g. Sentry self-hosted), opt-in | Respect privacy positioning                                                   |

---

## 4. Package List (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State management
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.6.1

  # Database
  drift: ^2.20.0
  sqlite3_flutter_libs: ^0.5.0
  path_provider: ^2.1.0
  path: ^1.9.0

  # Routing
  go_router: ^14.0.0

  # Recurrence
  rrule: ^0.2.16

  # Notifications
  flutter_local_notifications: ^18.0.0
  timezone: ^0.9.0

  # Calendar UI
  table_calendar: ^3.1.0

  # Utilities
  uuid: ^4.5.0
  collection: ^1.18.0
  equatable: ^2.0.5

  # Localization (optional but recommended)
  intl: ^0.19.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.0
  riverpod_generator: ^2.6.1
  drift_dev: ^2.20.0
  mocktail: ^1.0.0
  integration_test:
    sdk: flutter
  very_good_analysis: ^6.0.0
```

Keep this list lean. Every added dependency is a maintenance burden for OSS contributors — prefer Flutter/Dart-native solutions over pulling in a package for something trivial.

---

## 5. Folder Structure

Feature-first architecture. Each feature owns its data, logic, and UI; `core/` holds cross-cutting infrastructure.

```
Tamam/
├── android/
├── ios/
├── lib/
│   ├── main.dart
│   ├── app.dart                      # MaterialApp.router setup, theming
│   │
│   ├── core/
│   │   ├── database/
│   │   │   ├── database.dart         # Drift @DriftDatabase definition
│   │   │   ├── tables/
│   │   │   │   ├── tasks_table.dart
│   │   │   │   ├── projects_table.dart
│   │   │   │   ├── tags_table.dart
│   │   │   │   ├── task_tags_table.dart      # join table
│   │   │   │   ├── subtasks_table.dart
│   │   │   │   └── recurrence_rules_table.dart
│   │   │   └── daos/
│   │   │       ├── task_dao.dart
│   │   │       ├── project_dao.dart
│   │   │       └── tag_dao.dart
│   │   │
│   │   ├── notifications/
│   │   │   ├── notification_service.dart
│   │   │   └── notification_scheduler.dart
│   │   │
│   │   ├── router/
│   │   │   └── app_router.dart
│   │   │
│   │   ├── theme/
│   │   │   ├── app_theme.dart
│   │   │   └── app_colors.dart
│   │   │
│   │   └── utils/
│   │       ├── date_utils.dart
│   │       └── id_generator.dart      # UUIDv7 helper
│   │
│   ├── features/
│   │   ├── tasks/
│   │   │   ├── data/
│   │   │   │   ├── task_repository.dart
│   │   │   │   └── models/task.dart
│   │   │   ├── application/
│   │   │   │   └── task_providers.dart      # Riverpod providers
│   │   │   └── presentation/
│   │   │       ├── screens/
│   │   │       │   ├── task_list_screen.dart
│   │   │       │   └── task_detail_screen.dart
│   │   │       └── widgets/
│   │   │           ├── task_tile.dart
│   │   │           └── quick_add_bar.dart
│   │   │
│   │   ├── projects/
│   │   │   ├── data/
│   │   │   ├── application/
│   │   │   └── presentation/
│   │   │
│   │   ├── tags/
│   │   │   ├── data/
│   │   │   ├── application/
│   │   │   └── presentation/
│   │   │
│   │   ├── calendar/
│   │   │   ├── application/
│   │   │   └── presentation/
│   │   │
│   │   ├── pomodoro/            # v1.x
│   │   │   ├── data/
│   │   │   ├── application/
│   │   │   └── presentation/
│   │   │
│   │   ├── habits/              # v1.x
│   │   │   ├── data/
│   │   │   ├── application/
│   │   │   └── presentation/
│   │   │
│   │   └── settings/
│   │       ├── application/
│   │       └── presentation/
│   │
│   └── shared/
│       ├── widgets/              # buttons, dialogs, empty states used across features
│       └── extensions/
│
├── test/
│   ├── core/
│   └── features/
│       └── tasks/
│           ├── task_repository_test.dart
│           └── recurrence_test.dart
│
├── integration_test/
│   └── task_flow_test.dart       # create → complete → verify recurrence regenerates
│
├── analysis_options.yaml
├── pubspec.yaml
├── LICENSE
├── README.md
└── CONTRIBUTING.md
```

**Rules that keep this maintainable:**

- UI never talks to Drift directly — always through a repository (`task_repository.dart`). This is your future sync insertion point.
- Riverpod providers live in `application/`, not scattered in widgets.
- Each feature folder should be deletable without breaking unrelated features (loose coupling).

---

## 6. Data Model (Drift schema, conceptual)

```
Task
  id: text (UUIDv7, PK)
  projectId: text (FK -> Project.id, nullable = "Inbox")
  title: text
  notes: text, nullable
  dueDate: datetime, nullable
  dueTime: datetime, nullable      # separate from date for "all day" vs timed
  priority: int (0=none,1=low,2=medium,3=high)
  isCompleted: bool
  completedAt: datetime, nullable
  recurrenceRuleId: text, nullable (FK -> RecurrenceRule.id)
  sortOrder: int
  createdAt: datetime
  updatedAt: datetime              # for future sync
  deletedAt: datetime, nullable    # soft delete, for future sync

SubTask
  id: text (PK)
  taskId: text (FK -> Task.id)
  title: text
  isCompleted: bool
  sortOrder: int

Project
  id: text (PK)
  name: text
  color: int (ARGB)
  icon: text, nullable
  sortOrder: int

Tag
  id: text (PK)
  name: text
  color: int, nullable

TaskTag (join table)
  taskId: text (FK)
  tagId: text (FK)

RecurrenceRule
  id: text (PK)
  rruleString: text        # store the raw RFC5545 RRULE string, let the rrule package parse it
  taskId: text (FK -> Task.id)
```

**Why UUIDs + `updatedAt`/`deletedAt` now:** even though nothing reads these yet, retrofitting sync-friendly keys onto an app already in users' hands (with autoincrement ints as foreign keys everywhere) is a genuinely painful migration. Paying this small cost now is cheap insurance.

**Recurrence generation approach:** don't pre-generate all future instances. Store the rule on the "template" task, and compute the next occurrence on completion (mark current instance done, use `rrule` to compute the next `dueDate`, reset `isCompleted`). This is how TickTick and Todoist both do it — far simpler than a table of generated instances.

---

## 7. Architecture Notes

**Layering per feature:**

```
Presentation (widgets, screens)
      ↓ watches
Application (Riverpod providers/notifiers)
      ↓ calls
Data (Repository)
      ↓ queries
Core/Database (Drift DAOs)
```

Widgets never import Drift types directly — they consume domain models (`Task`, `Project`) exposed by the repository, not Drift's generated row classes. This keeps the DB swappable and keeps widget tests free of DB setup.

**Reactive updates:** Drift DAOs expose `Stream<List<Task>>` via watch queries; repositories forward these as-is or mapped to domain models; Riverpod `StreamProvider`/`AsyncNotifier` consumes them. Result: any DB write anywhere in the app automatically updates every screen watching that data — no manual cache invalidation.

**Error handling:** wrap repository methods to return a `Result<T>`-style type (or use a package like `fpdart` if you like functional patterns, or keep it simple with try/catch + custom exceptions) so UI can show meaningful errors instead of crashing on constraint violations.

---

## 8. Sync-Readiness Checklist (do these now, even local-only)

- [ ] UUIDv7 primary keys everywhere (not autoincrement)
- [ ] `updatedAt` timestamp on every mutable table, updated on every write
- [ ] `deletedAt` soft-delete instead of hard `DELETE`
- [ ] All writes go through repositories, never raw DAO calls from UI
- [ ] JSON export/import (backup feature) — this becomes your migration tool when sync ships, and it's a good v1.x feature anyway
- [ ] Avoid DB-generated values the client can't reproduce offline (e.g. server timestamps) — always generate client-side

When you're ready for sync, this foundation lets you evaluate PocketBase, Supabase, or a custom Go/Rust backend purely as a transport/storage layer, without touching your Flutter data model.

---

## 9. Roadmap / Milestones

**Milestone 1 — Core CRUD (2-4 weeks)**
Drift schema, task/project/tag CRUD, basic list UI, Riverpod wiring, navigation shell.

**Milestone 2 — Task details & organization (2-3 weeks)**
Subtasks, priorities, due dates, drag-reorder, smart lists (Today/Next 7 Days/All).

**Milestone 3 — Recurrence & notifications (2 weeks)**
rrule integration, notification scheduling, permission handling (Android 13+/iOS).

**Milestone 4 — Calendar view (1-2 weeks)**
table_calendar integration, month/week toggle, tap-to-view-day-tasks.

**Milestone 5 — Polish (2 weeks)**
Theming, empty states, onboarding, settings screen, JSON backup/restore.

**Milestone 6 — v1.x features**
Pomodoro, habits, search, widgets — each as an independently shippable feature module.

---

## 10. OSS Project Hygiene

- **License:** MIT (maximizes contribution) unless you specifically want to prevent closed-source SaaS forks, in which case AGPL — decide before your first outside PR, hard to change later.
- `CONTRIBUTING.md` with setup steps, coding conventions, and how to run tests.
- Issue templates (bug report / feature request) and a `good first issue` label to attract contributors.
- `analysis_options.yaml` with `very_good_analysis` or `flutter_lints` enforced in CI so PRs can't merge with lint failures.
- Conventional commits (optional but helps with changelog generation).

---

## 11. Open Questions to Revisit Later

- Sync backend choice (PocketBase vs Supabase vs custom) — revisit once local app is stable
- Whether habits and Pomodoro deserve their own local tables now or can stay isolated modules added later
- i18n strategy — worth deciding before you have translated strings scattered across 50 files
