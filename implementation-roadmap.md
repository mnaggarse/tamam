# Tamam — Agent-Ready Implementation Roadmap

Each phase below is written to be handed to an AI coding agent as a **standalone prompt**. Every phase:

- Builds on the previous phase's output (specified explicitly under "Depends on")
- Includes **both** the data/logic layer AND the corresponding UI — nothing is "backend only"
- Ends in a compiling, runnable, manually-testable state (never leaves the app broken)
- Has explicit **Out of scope** items so the agent doesn't scope-creep into later phases
- Lists exact files to create/modify, so agents working phase-by-phase stay consistent

**Stack reminder (paste into every agent prompt if running phases in separate sessions):**
Flutter, Riverpod (+ riverpod_generator), Drift (SQLite), go_router, rrule, flutter_local_notifications + timezone, table_calendar, Material 3, feature-first folder structure under `lib/features/<feature>/{data,application,presentation}` with shared infra in `lib/core/`. Local-only app, no backend, no auth. See project-plan.md for full architecture rationale.

---

## Phase 0 — Project Scaffolding

**Depends on:** nothing (starting point)

**Goal:** A running Flutter app with the full folder skeleton, theme, routing shell, and dependencies installed — but no real features yet. This is the foundation every later phase builds on.

**Tasks:**

- Create Flutter project, set package name/app name to "Tamam" (or user's chosen name)
- Add all dependencies from the package list (Riverpod, Drift, go_router, rrule, flutter_local_notifications, timezone, table_calendar, uuid, equatable, dev deps: build_runner, riverpod_generator, drift_dev, mocktail, very_good_analysis)
- Create the full folder structure exactly as specified in project-plan.md §5 (empty feature folders are fine — `tasks/`, `projects/`, `tags/`, `calendar/`, `pomodoro/`, `habits/`, `settings/` each with `data/`, `application/`, `presentation/` subfolders)
- Set up `lib/core/theme/app_theme.dart` with Material 3 light + dark ThemeData (basic, not final polish)
- Set up `lib/core/router/app_router.dart` using go_router with placeholder routes: `/` (home shell with bottom nav: Tasks, Calendar, Settings — 3 tabs), each showing a simple "Coming soon" screen
- Wire `ProviderScope` in `main.dart`, `MaterialApp.router` in `app.dart`
- Add `analysis_options.yaml` with `very_good_analysis`
- Add a smoke test in `test/` that pumps the app and confirms it builds

**Acceptance criteria:**

- `flutter run` launches the app with a bottom nav bar with 3 tabs, each showing placeholder content
- `flutter analyze` passes with no errors
- `flutter test` passes (smoke test)

**Out of scope:** any database, any real feature UI, theming polish.

**Files created:** `lib/main.dart`, `lib/app.dart`, `lib/core/theme/*`, `lib/core/router/app_router.dart`, full empty folder tree, `pubspec.yaml`, `analysis_options.yaml`, `test/smoke_test.dart`

---

## Phase 1 — Database Foundation + Projects Feature (data + UI)

**Depends on:** Phase 0

**Goal:** Stand up Drift, implement the `Project` table end-to-end, and ship a working Projects screen. This phase proves out the full data→UI pipeline (Drift → repository → Riverpod → widget) that every later feature will repeat.

**Tasks — Data layer:**

- `lib/core/database/database.dart`: Drift `@DriftDatabase` setup with SQLite connection (use `path_provider` for the app documents directory)
- `lib/core/database/tables/projects_table.dart`: `Project` table — `id` (text, PK, UUIDv7), `name` (text), `color` (int), `icon` (text, nullable), `sortOrder` (int), `createdAt`, `updatedAt` (datetime), `deletedAt` (datetime, nullable)
- `lib/core/database/daos/project_dao.dart`: CRUD methods + a `watchAllProjects()` stream query (excluding soft-deleted rows, ordered by `sortOrder`)
- `lib/core/utils/id_generator.dart`: UUIDv7 generator helper (used by every future table)
- `lib/features/projects/data/project_repository.dart`: wraps the DAO, exposes domain-friendly methods (`createProject`, `updateProject`, `softDeleteProject`, `watchProjects`), maps Drift rows to a plain `Project` domain model in `lib/features/projects/data/models/project.dart`

**Tasks — Application layer:**

- `lib/features/projects/application/project_providers.dart`: Riverpod `StreamProvider` exposing `watchProjects()`, plus a `ProjectController` (Notifier) for create/update/delete actions

**Tasks — UI layer:**

- `lib/features/projects/presentation/screens/project_list_screen.dart`: list of projects with color swatch, name, tap to edit
- `lib/features/projects/presentation/screens/project_edit_screen.dart`: form to create/edit a project (name field, color picker — a simple grid of ~12 preset colors is fine, no need for a full color wheel)
- Add a "+" FAB on the project list that opens the edit screen in create mode
- Wire a "Projects" entry into the Settings tab (or add a 4th nav destination — your call, but it must be reachable from the running app)
- Swipe-to-delete or a delete button on each project row (calls `softDeleteProject`)

**Acceptance criteria:**

- User can create a project with a name and color, see it in the list, edit it, and delete it
- Data persists across app restarts (kill and relaunch app, projects still there)
- `deletedAt` is set on delete, not a hard SQL delete (verify by checking the row still exists in DB, just filtered from `watchProjects()`)
- All new code has at least one repository-level test using an in-memory Drift database

**Out of scope:** tasks, tags, any relation to other tables. Projects are a standalone list at this point.

**Files created/modified:** everything under `lib/core/database/`, `lib/features/projects/**`, plus router entry for the projects screen(s).

---

## Phase 2 — Tags Feature (data + UI)

**Depends on:** Phase 1 (repeats the same pattern as Projects — use Phase 1's code as the template)

**Goal:** Same full pipeline as Phase 1, applied to `Tag`. Deliberately kept separate from Projects so the agent works from a clean, small diff.

**Tasks:**

- `lib/core/database/tables/tags_table.dart`: `Tag` table — `id`, `name`, `color` (nullable), `createdAt`, `updatedAt`, `deletedAt`
- `lib/core/database/daos/tag_dao.dart` — same CRUD + watch pattern as `project_dao.dart`
- `lib/features/tags/data/tag_repository.dart` + `models/tag.dart`
- `lib/features/tags/application/tag_providers.dart`
- `lib/features/tags/presentation/screens/tag_list_screen.dart` and `tag_edit_screen.dart` — mirror the Projects UI (list + create/edit form), reachable from Settings
- Repository test mirroring Phase 1's test

**Acceptance criteria:**

- User can create, edit, delete tags from a Tags screen under Settings
- Persists across restarts, soft-delete confirmed

**Out of scope:** attaching tags to tasks (that's Phase 5). Tags exist standalone for now, same as Projects did.

**Files created/modified:** `lib/core/database/tables/tags_table.dart`, `lib/core/database/daos/tag_dao.dart`, `lib/features/tags/**`

---

## Phase 3 — Core Tasks Feature: Create, View, Edit (data + UI)

**Depends on:** Phase 1 (Tasks reference Project via `projectId`)

**Goal:** The centerpiece feature. Basic task CRUD with title, notes, and project assignment — no due dates, priority, subtasks, or tags yet (those are later phases so this one stays small and correct).

**Tasks — Data layer:**

- `lib/core/database/tables/tasks_table.dart`: `Task` table — `id`, `projectId` (nullable FK to Project, null = "Inbox"), `title`, `notes` (nullable), `isCompleted` (bool, default false), `completedAt` (nullable), `sortOrder` (int), `createdAt`, `updatedAt`, `deletedAt` (nullable). Add columns for `dueDate`, `dueTime`, `priority`, `recurrenceRuleId` now (nullable/default) even though they're unused until later phases — this avoids a schema migration in Phase 4.
- `lib/core/database/daos/task_dao.dart`: CRUD + `watchAllTasks()`, `watchTasksByProject(projectId)`, both excluding soft-deleted and (for now) excluding completed unless explicitly requested
- `lib/features/tasks/data/task_repository.dart` + `models/task.dart` (domain model mirrors the table for now; will grow in later phases)

**Tasks — Application layer:**

- `lib/features/tasks/application/task_providers.dart`: `StreamProvider` for the task list (default: Inbox / all incomplete tasks), `TaskController` Notifier with `createTask`, `updateTask`, `toggleComplete`, `softDeleteTask`

**Tasks — UI layer:**

- `lib/features/tasks/presentation/screens/task_list_screen.dart`: this becomes the "Tasks" tab's real content (replacing Phase 0's placeholder). Shows tasks grouped by project or flat list with project chip per row. Checkbox to complete, tap row to open detail/edit.
- `lib/features/tasks/presentation/widgets/task_tile.dart`: single task row (checkbox, title, project color dot)
- `lib/features/tasks/presentation/screens/task_detail_screen.dart`: view/edit a task — title, notes, project picker (dropdown of existing projects from Phase 1)
- `lib/features/tasks/presentation/widgets/quick_add_bar.dart`: a simple text field + "Add" button at the bottom of the task list for fast task creation (title only, defaults to Inbox)
- Swipe-to-delete on task rows

**Acceptance criteria:**

- User can quick-add a task by title, see it appear in the list instantly (via the Drift stream)
- User can tap a task to open its detail screen, edit title/notes/project, save, and see changes reflected in the list
- User can check a task complete (it should disappear from the default "incomplete" view — a "show completed" toggle is a nice-to-have but not required here)
- User can delete a task
- Everything persists across restart
- Repository test covering create/update/complete/delete

**Out of scope:** due dates, priority, subtasks, tags-on-tasks, recurrence, drag-reorder, smart lists beyond the default view. These are explicitly Phases 4-8.

**Files created/modified:** `lib/core/database/tables/tasks_table.dart`, `lib/core/database/daos/task_dao.dart`, `lib/features/tasks/**`, router updated so the Tasks tab shows `task_list_screen.dart`.

---

## Phase 4 — Due Dates, Priority & Smart Lists (data + UI)

**Depends on:** Phase 3

**Goal:** Activate the `dueDate`, `dueTime`, and `priority` columns already present in the schema (from Phase 3) with real UI, and add the smart list views that filter on them.

**Tasks:**

- Update `task_repository.dart` / domain model: expose and allow setting `dueDate`, `dueTime`, `priority` (int 0-3)
- `task_detail_screen.dart`: add a due date picker (date + optional time), and a priority selector (4 options: None/Low/Medium/High, e.g. as colored flag icons or a segmented control)
- `task_tile.dart`: show due date (formatted, e.g. "Today", "Tomorrow", "Mon 12 Jan" — build a small date-label helper in `core/utils/date_utils.dart`) and a priority color indicator
- DAO: add `watchTasksDueToday()`, `watchTasksDueNext7Days()`, `watchAllIncompleteTasks()`, `watchCompletedTasks()`
- New smart list screens or a single parameterized screen: **Today**, **Next 7 Days**, **All**, **Completed** — accessible via a drawer, top tabs, or a segmented picker at the top of the Tasks tab (agent's choice, keep it simple)
- Sort task lists by priority then due date within each smart list (reasonable default; doesn't need to be configurable yet)

**Acceptance criteria:**

- Setting a due date/time and priority on a task persists and displays correctly on the task tile
- Today / Next 7 Days / All / Completed views each show the correct filtered set, verified by creating tasks with varying due dates and checking each list
- Overdue tasks (due date in the past, incomplete) are visually distinguished (e.g. red date text) in at least the "All" and "Today" views

**Out of scope:** calendar view (Phase 10), recurrence (Phase 8), subtasks (Phase 6), tags (Phase 5).

**Files modified:** `lib/features/tasks/**`, `lib/core/database/daos/task_dao.dart`, `lib/core/utils/date_utils.dart`

---

## Phase 5 — Tags on Tasks (data + UI)

**Depends on:** Phase 2 (Tags exist) and Phase 3 (Tasks exist)

**Goal:** Wire the many-to-many relationship between tasks and tags, with UI to assign and filter by tags.

**Tasks:**

- `lib/core/database/tables/task_tags_table.dart`: join table — `taskId` (FK), `tagId` (FK), composite behavior enforced at the DAO/repository level (no duplicate pairs)
- `lib/core/database/daos/task_tag_dao.dart`: `addTagToTask`, `removeTagFromTask`, `watchTagsForTask(taskId)`, `watchTasksForTag(tagId)`
- Update `task_repository.dart` to expose tags as part of the task's returned domain model (a `List<Tag>` field), likely via a joined/combined query
- `task_detail_screen.dart`: add a tag picker (multi-select chips from existing tags, "+ new tag" shortcut that opens the tag creation flow inline)
- `task_tile.dart`: show tag chips (small, 1-2 visible + "+N more" if many)
- Task list screen: add a filter bar/chip row to filter the current view by one or more tags

**Acceptance criteria:**

- User can attach multiple tags to a task and remove them
- Tag filter on the task list correctly narrows results
- Deleting a tag (from Phase 2's tag screen) removes its associations without crashing (verify the join rows are cleaned up or the query gracefully ignores orphaned refs)

**Out of scope:** nothing new introduced beyond tag-task wiring; don't touch recurrence/subtasks here.

**Files created/modified:** `lib/core/database/tables/task_tags_table.dart`, `lib/core/database/daos/task_tag_dao.dart`, updates to `lib/features/tasks/**` and `lib/features/tags/**`

---

## Phase 6 — Subtasks (data + UI)

**Depends on:** Phase 3

**Goal:** Add checklist-style subtasks within a task.

**Tasks:**

- `lib/core/database/tables/subtasks_table.dart`: `SubTask` — `id`, `taskId` (FK), `title`, `isCompleted`, `sortOrder`, `createdAt`, `updatedAt`, `deletedAt`
- `lib/core/database/daos/subtask_dao.dart`: CRUD + `watchSubtasksForTask(taskId)`
- `lib/features/tasks/data/` — extend repository with subtask methods, or a small dedicated `subtask_repository.dart` if that reads cleaner
- `task_detail_screen.dart`: add a subtask section — list of checkable subtask rows, inline "add subtask" text field, swipe-to-delete per subtask
- `task_tile.dart`: show a small progress indicator if the task has subtasks (e.g. "2/5")

**Acceptance criteria:**

- User can add, complete, and delete subtasks within a task's detail screen
- Subtask completion state persists and the progress indicator on the parent task tile updates correctly
- Completing all subtasks does NOT auto-complete the parent task (keep behaviors independent unless you explicitly want that — note it as a deliberate choice)

**Out of scope:** drag-reorder of subtasks (fold into Phase 7 if desired, or treat as a nice-to-have here — agent's call, not blocking).

**Files created/modified:** `lib/core/database/tables/subtasks_table.dart`, `lib/core/database/daos/subtask_dao.dart`, updates to `lib/features/tasks/**`

---

## Phase 7 — Drag-to-Reorder (UI-focused, minimal data changes)

**Depends on:** Phase 3 (and Phase 6 if reordering subtasks too)

**Goal:** Manual reordering of tasks within a list (and optionally subtasks within a task), persisted via the existing `sortOrder` column.

**Tasks:**

- Wrap the task list in a reorderable list widget (`ReorderableListView` or similar)
- On reorder, recompute `sortOrder` for affected rows and persist via a batch repository update (`reorderTasks(List<String> orderedIds)`)
- Same treatment for the subtask list inside `task_detail_screen.dart` if in scope
- Ensure watch queries order by `sortOrder` (should already be true from earlier phases — verify)

**Acceptance criteria:**

- Dragging a task to a new position persists across restart
- Reordering doesn't disturb tasks in other projects/lists (sortOrder scoping is sane — either global or per-project, pick one and be consistent, per-project is recommended)

**Out of scope:** cross-list drag (dragging a task from one project to another via drag-and-drop) — that's a nice-to-have for a much later polish phase, not required here.

**Files modified:** `lib/features/tasks/presentation/**`, repository reorder method.

---

## Phase 8 — Recurrence (data + UI)

**Depends on:** Phase 4 (due dates must exist)

**Goal:** Recurring tasks using the `rrule` package.

**Tasks:**

- `lib/core/database/tables/recurrence_rules_table.dart`: `RecurrenceRule` — `id`, `taskId` (FK, one-to-one with the "template" task), `rruleString` (text, raw RFC5545 RRULE)
- `lib/core/database/daos/recurrence_dao.dart`
- `lib/features/tasks/data/task_repository.dart`: on `toggleComplete` for a task that has a recurrence rule, instead of just marking complete: mark the current instance complete, use `rrule` to compute the next occurrence date from `rruleString`, and either (a) update the same task row's `dueDate` and reset `isCompleted` to false, or (b) create a new task row for the next occurrence and mark the old one permanently complete — **choose approach (a)** for v1 simplicity (single evolving row) unless the agent has strong reason otherwise; document the choice in a code comment since it affects history/analytics later
- `task_detail_screen.dart`: add a "Repeat" section — simple presets (Daily, Weekly, Monthly, Every weekday) that map to canned RRULE strings, plus a "Custom" option if time allows (custom builder can be deferred — presets are enough for v1 completeness)
- `task_tile.dart`: show a repeat icon on recurring tasks

**Acceptance criteria:**

- Creating a task with "Repeat: Daily" and completing it causes it to reappear with tomorrow's due date, still incomplete
- Repeat icon displays correctly
- Unit test: given a fixed RRULE string and completion date, `rrule` computation returns the expected next date (test the pure logic, not just the UI)

**Out of scope:** editing/skipping individual occurrences of a recurring series, complex custom recurrence UI beyond presets.

**Files created/modified:** `lib/core/database/tables/recurrence_rules_table.dart`, `lib/core/database/daos/recurrence_dao.dart`, updates to `lib/features/tasks/**`

---

## Phase 9 — Local Notifications (data + UI)

**Depends on:** Phase 4 (needs due dates/times to schedule against)

**Goal:** Schedule and manage local reminder notifications tied to task due times.

**Tasks:**

- `lib/core/notifications/notification_service.dart`: initialize `flutter_local_notifications` + `timezone`, request permissions (handle Android 13+ runtime permission and iOS permission prompts)
- `lib/core/notifications/notification_scheduler.dart`: `scheduleForTask(Task task)`, `cancelForTask(String taskId)` — called from the task repository whenever a task with a due date/time is created, updated, or deleted, so notifications always stay in sync with task state
- Task detail screen: add a "Remind me" toggle/picker (e.g. "At time of due date", "15 min before", "1 hour before", "None") stored as a new nullable field on the task (`reminderMinutesBefore`, int, nullable) — small schema addition
- Settings screen: add a notification permission status indicator + a button to open system settings if permission was denied

**Acceptance criteria:**

- Setting a due time + reminder on a task schedules a real local notification (test on a physical device/emulator by setting a due time 1-2 minutes out)
- Editing or deleting the task correctly reschedules or cancels the notification (no duplicate or orphaned notifications — verify via the notification plugin's pending-notifications list)
- Permission denial is handled gracefully (app doesn't crash, shows guidance instead)

**Out of scope:** push notifications (not applicable, local-only app), notification action buttons (snooze/complete from notification) — good v1.x nice-to-have, not required now.

**Files created/modified:** `lib/core/notifications/**`, small schema addition to `tasks_table.dart` for `reminderMinutesBefore`, updates to `task_detail_screen.dart` and `settings/presentation/**`

---

## Phase 10 — Calendar View (UI-focused, reads existing data)

**Depends on:** Phase 4

**Goal:** A calendar tab showing tasks by due date, using `table_calendar`.

**Tasks:**

- `lib/features/calendar/application/calendar_providers.dart`: provider that maps the task stream into a `Map<DateTime, List<Task>>` for the calendar widget's event loader
- `lib/features/calendar/presentation/screens/calendar_screen.dart`: replaces Phase 0's placeholder Calendar tab. Month/week toggle, day cells show a dot/marker if tasks are due that day, tapping a day shows that day's tasks in a list below the calendar (reuse `task_tile.dart`)
- Tapping a task in the day list opens `task_detail_screen.dart` (reuse existing route)

**Acceptance criteria:**

- Calendar correctly marks days with due tasks
- Selecting a day shows the correct task list, matching what Phase 4's "Today" logic would show for that date
- Navigating months/weeks works smoothly, no jank on typical task volumes (tens to low hundreds of tasks)

**Out of scope:** creating tasks directly from the calendar (nice-to-have, not required), drag-to-reschedule on the calendar.

**Files created/modified:** `lib/features/calendar/**`, router update.

---

## Phase 11 — Theming, Empty States & Onboarding Polish

**Depends on:** Phases 0-10 (this is a polish pass over the whole app)

**Goal:** Make the app feel finished, not scaffolded.

**Tasks:**

- Finalize light/dark ThemeData (typography scale, consistent spacing constants in `core/theme/`)
- Add a dark/light/system theme toggle in Settings, persisted (simple key-value storage, e.g. `shared_preferences` — new minimal dependency, justified here)
- Add empty-state illustrations/messages to: empty task list, empty project list, empty tag list, empty calendar day
- Add a first-run onboarding: 2-3 simple screens explaining the app is local-only/private, then land on the Tasks tab
- Consistent iconography and spacing pass across all screens built in Phases 1-10

**Acceptance criteria:**

- Fresh install shows onboarding once, then never again (persisted flag)
- Theme toggle works and persists across restart
- No screen in the app shows a raw blank white space when data is empty — every list has a designed empty state

**Out of scope:** functional changes to any feature — this phase is UI/UX polish only, don't touch data layers.

**Files modified:** `lib/core/theme/**`, new `lib/features/onboarding/**`, empty-state widgets added to each feature's `presentation/widgets/`.

---

## Phase 12 — Backup & Restore (data + UI)

**Depends on:** Phases 1-8 (needs the full schema to be stable)

**Goal:** Export the full local database to a JSON file and re-import it. Doubles as the future migration path to a sync backend.

**Tasks:**

- `lib/core/database/backup/backup_service.dart`: serialize all tables (projects, tags, tasks, subtasks, task_tags, recurrence_rules) to a single versioned JSON structure (include a `schemaVersion` field); deserialize + restore (with a clear "this will overwrite existing data" confirmation flow)
- Use `share_plus` or platform file picker (new minimal dependency) to let the user save the export file and pick a file to import
- Settings screen: "Export Data" and "Import Data" actions with confirmation dialogs

**Acceptance criteria:**

- Exporting then importing into a fresh app install fully restores all projects, tags, tasks (with due dates, priority, subtasks, tags, recurrence) exactly
- Import validates the file (rejects malformed/foreign JSON gracefully with an error message, doesn't crash)

**Out of scope:** partial/selective import, automatic cloud backup (that's the future sync phase entirely, not this).

**Files created:** `lib/core/database/backup/**`, updates to `settings/presentation/**`

---

## Phase 13 — Search (data + UI)

**Depends on:** Phase 5 (tags), Phase 4 (due dates) — searches across the fuller task model

**Goal:** Full-text search across task titles and notes.

**Tasks:**

- DAO: `searchTasks(String query)` using SQL `LIKE` (SQLite FTS5 is a nice upgrade but plain `LIKE` is sufficient for v1 data volumes)
- `lib/features/tasks/presentation/screens/search_screen.dart`: search bar + results list (reuse `task_tile.dart`), accessible from an icon on the Tasks tab app bar
- Debounce input so search doesn't query on every keystroke

**Acceptance criteria:**

- Typing a query returns matching tasks by title or notes content, updating live as the user types
- Empty query shows no results / a prompt state, not the entire task list

**Out of scope:** search across projects/tags by name, advanced filters (by:project, priority:high syntax) — good v2 idea, not now.

**Files created/modified:** `lib/features/tasks/**`, `task_dao.dart`

---

## Phase 14 — Pomodoro Timer (data + UI)

**Depends on:** Phase 3 (ties sessions to tasks)

**Goal:** A focus timer feature, independent module, optionally linked to a task.

**Tasks:**

- `lib/core/database/tables/pomodoro_sessions_table.dart`: `id`, `taskId` (nullable FK), `startedAt`, `durationMinutes`, `completed` (bool)
- `lib/features/pomodoro/data/pomodoro_repository.dart`
- `lib/features/pomodoro/application/pomodoro_providers.dart`: timer state machine (idle/running/paused/break) as a Riverpod Notifier
- `lib/features/pomodoro/presentation/screens/pomodoro_screen.dart`: timer UI (circular progress, start/pause/reset, optional task picker to link the session), reachable from a new nav entry or from within `task_detail_screen.dart` as a "Start focus session" button
- Show a running-session indicator/badge somewhere persistent (e.g. task tile of the linked task) while active

**Acceptance criteria:**

- User can start a 25-minute (configurable) timer, optionally linked to a task, and it counts down correctly even if the app is backgrounded briefly (verify state isn't lost on a quick app switch)
- Completed sessions are recorded and viewable (a simple list of past sessions is enough for v1, no charts required yet)

**Out of scope:** background execution when the app is fully killed (that needs platform-specific background task APIs — flag as a known limitation, don't attempt in this phase), statistics/charts.

**Files created:** `lib/core/database/tables/pomodoro_sessions_table.dart`, `lib/features/pomodoro/**`

---

## Phase 15 — Habit Tracking (data + UI)

**Depends on:** Phase 0 only (deliberately independent of Tasks — habits are a separate concept)

**Goal:** Standalone habit tracking with streaks, as its own module.

**Tasks:**

- `lib/core/database/tables/habits_table.dart`: `id`, `name`, `color`, `targetFrequency` (e.g. "daily" for v1, keep it simple), `createdAt`, `deletedAt`
- `lib/core/database/tables/habit_logs_table.dart`: `id`, `habitId` (FK), `date` (date only), `completed` (bool)
- `lib/features/habits/data/habit_repository.dart` (streak calculation logic lives here — pure function, unit test it)
- `lib/features/habits/application/habit_providers.dart`
- `lib/features/habits/presentation/screens/habit_list_screen.dart`: list of habits with a checkbox for "today" and current streak count shown per habit
- `lib/features/habits/presentation/screens/habit_detail_screen.dart`: a simple calendar heatmap of past completions (can reuse `table_calendar` in a custom-rendered mode, or a simple grid — agent's call)
- New nav entry for Habits (4th tab, or nested under a "More" tab if you want to keep bottom nav to 3-4 items)

**Acceptance criteria:**

- User can create a habit, mark it done for today, see the streak count update correctly (unit test the streak calculation with a few date sequences: consecutive days, a gap, marking today after missing yesterday)
- Historical completions display correctly in the detail view

**Out of scope:** non-daily frequency habits (e.g. "3x per week") — note as a v2 idea, keep v1 daily-only for a clean, correct implementation.

**Files created:** `lib/core/database/tables/habits_table.dart`, `lib/core/database/tables/habit_logs_table.dart`, `lib/features/habits/**`

---

## Phase 16 — Home Screen Widgets _(optional, platform-specific)_

**Depends on:** Phase 4

**Goal:** iOS/Android home screen widget showing today's tasks and a quick-add shortcut.

**Tasks:**

- Use `home_widget` package (new dependency) to bridge Flutter data to native widget views
- Android: a simple `RemoteViews`-based widget listing today's incomplete tasks
- iOS: a WidgetKit widget (requires native Swift code in `ios/`, not pure Dart — flag this clearly to the agent as needing native platform work, not just Flutter)
- Sync widget data on every relevant task write (hook into the repository layer, same pattern as notifications in Phase 9)

**Acceptance criteria:**

- Widget added to home screen shows today's tasks and updates within a reasonable delay after in-app changes

**Out of scope:** interactive widget actions (checking off a task from the widget) — static display only for v1.

**Note to agent:** this phase requires native iOS/Android development skills beyond Flutter/Dart. If the agent executing this phase is Dart/Flutter-only, flag this phase for human/specialist handling rather than attempting the native widget code blind.

**Files created:** `lib/core/widgets_bridge/**`, native widget files under `android/app/src/main/` and `ios/`.

---

## How to Use This With an AI Agent

1. Feed phases **in order** — each assumes the previous phases' code exists and compiles.
2. For each phase, give the agent: this phase's section verbatim, the current repo state (or have it work directly in the repo), and the "Stack reminder" block at the top of this doc if it's a fresh session with no prior context.
3. After each phase, verify the **Acceptance criteria** manually (or have the agent write/run the tests specified) before moving to the next phase — don't chain phases without checking the previous one actually works, since later phases assume correctness of earlier ones.
4. Phases 14, 15, 16 (Pomodoro, Habits, Widgets) are independent of each other and can be done in any order, or in parallel by different agent sessions, once their stated dependencies are met.
5. If a phase feels too large for one agent session in practice, it can be split further along its own "Data layer / Application layer / UI layer" task groupings — each was written to be splittable at those seams if needed.
