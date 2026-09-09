import 'package:drift/drift.dart';
import 'package:tamam/core/database/database.dart';
import 'package:tamam/core/database/tables/projects_table.dart';

part 'project_dao.g.dart';

/// Data access object for the [Projects] table.
@DriftAccessor(tables: [Projects])
class ProjectDao extends DatabaseAccessor<AppDatabase> with _$ProjectDaoMixin {
  /// Creates a [ProjectDao] accessor.
  ProjectDao(super.db);

  /// Watches all non-deleted projects, ordered by sortOrder then createdAt.
  Stream<List<ProjectEntry>> watchAllProjects() {
    return (select(projects)
          ..where((tbl) => tbl.deletedAt.isNull())
          ..orderBy([
            (tbl) => OrderingTerm.asc(tbl.sortOrder),
            (tbl) => OrderingTerm.asc(tbl.createdAt),
          ]))
        .watch();
  }

  /// Retrieves all non-deleted projects.
  Future<List<ProjectEntry>> getAllProjects() {
    return (select(projects)
          ..where((tbl) => tbl.deletedAt.isNull())
          ..orderBy([
            (tbl) => OrderingTerm.asc(tbl.sortOrder),
            (tbl) => OrderingTerm.asc(tbl.createdAt),
          ]))
        .get();
  }

  /// Retrieves a single project by its [id].
  Future<ProjectEntry?> getProjectById(String id) {
    return (select(projects)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  /// Inserts a new project.
  Future<int> insertProject(ProjectsCompanion companion) {
    return into(projects).insert(companion);
  }

  /// Updates an existing project.
  Future<bool> updateProject(ProjectsCompanion companion) {
    return update(projects).replace(companion);
  }

  /// Soft-deletes a project by marking `deletedAt` and updating `updatedAt`.
  Future<int> softDeleteProject(String id, DateTime deletedAt) {
    return (update(projects)..where((tbl) => tbl.id.equals(id))).write(
      ProjectsCompanion(
        deletedAt: Value(deletedAt),
        updatedAt: Value(deletedAt),
      ),
    );
  }

  /// Physical deletion of a project by [id] (used primarily for test cleanup).
  Future<int> hardDeleteProject(String id) {
    return (delete(projects)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// Retrieves all projects including soft-deleted ones (for verification/sync).
  Future<List<ProjectEntry>> getRawProjects() {
    return select(projects).get();
  }
}
