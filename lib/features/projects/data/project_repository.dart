import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tamam/core/database/daos/project_dao.dart';
import 'package:tamam/core/database/database.dart';
import 'package:tamam/core/utils/id_generator.dart';
import 'package:tamam/features/projects/data/models/project.dart';

/// Repository managing Project domain entities.
class ProjectRepository {
  /// Creates a [ProjectRepository].
  const ProjectRepository(this._projectDao);

  final ProjectDao _projectDao;

  /// Watches all active (non-deleted) projects.
  Stream<List<Project>> watchProjects() {
    return _projectDao.watchAllProjects().map(
          (entries) => entries.map(_entryToDomain).toList(),
        );
  }

  /// Retrieves all active (non-deleted) projects.
  Future<List<Project>> getProjects() async {
    final entries = await _projectDao.getAllProjects();
    return entries.map(_entryToDomain).toList();
  }

  /// Retrieves a project by [id].
  Future<Project?> getProject(String id) async {
    final entry = await _projectDao.getProjectById(id);
    return entry != null ? _entryToDomain(entry) : null;
  }

  /// Creates and stores a new project.
  Future<String> createProject({
    required String name,
    required int color,
    String? icon,
    int sortOrder = 0,
  }) async {
    final id = IdGenerator.generateUuidV7();
    final now = DateTime.now();

    await _projectDao.insertProject(
      ProjectsCompanion.insert(
        id: id,
        name: name,
        color: color,
        icon: Value(icon),
        sortOrder: Value(sortOrder),
        createdAt: now,
        updatedAt: now,
      ),
    );

    return id;
  }

  /// Updates an existing project.
  Future<void> updateProject(Project project) async {
    final now = DateTime.now();

    await _projectDao.updateProject(
      ProjectsCompanion(
        id: Value(project.id),
        name: Value(project.name),
        color: Value(project.color),
        icon: Value(project.icon),
        sortOrder: Value(project.sortOrder),
        createdAt: Value(project.createdAt),
        updatedAt: Value(now),
        deletedAt: Value(project.deletedAt),
      ),
    );
  }

  /// Soft-deletes a project by its [id].
  Future<void> softDeleteProject(String id) async {
    final now = DateTime.now();
    await _projectDao.softDeleteProject(id, now);
  }

  /// Maps a Drift [ProjectEntry] row to a [Project] domain entity.
  static Project _entryToDomain(ProjectEntry entry) {
    return Project(
      id: entry.id,
      name: entry.name,
      color: entry.color,
      icon: entry.icon,
      sortOrder: entry.sortOrder,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
      deletedAt: entry.deletedAt,
    );
  }
}

/// Riverpod provider for the [ProjectRepository].
final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  final dao = ref.watch(projectDaoProvider);
  return ProjectRepository(dao);
});
