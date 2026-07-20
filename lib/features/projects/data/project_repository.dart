import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../domain/project.dart';

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return ProjectRepository(ref.watch(appDatabaseProvider));
});

final projectsProvider = FutureProvider<List<Project>>((ref) {
  return ref.watch(projectRepositoryProvider).findAll();
});

final projectCountProvider = FutureProvider<int>((ref) {
  return ref.watch(projectRepositoryProvider).count();
});

final projectByIdProvider = FutureProvider.family<Project?, int>((ref, id) {
  return ref.watch(projectRepositoryProvider).findById(id);
});

class ProjectRepository {
  ProjectRepository(this._database);

  final AppDatabase _database;

  Future<List<Project>> findAll() async {
    final rows = await _database.customSelect('''
      SELECT id, name, version, default_material, estimated_weight,
             print_minutes, infill_percent, layer_height, nozzle_size,
             suggested_price, file_path, notes, active
      FROM projects
      ORDER BY name COLLATE NOCASE, version COLLATE NOCASE
      ''', readsFrom: const {}).get();
    return rows.map((row) => Project.fromMap(row.data)).toList();
  }

  Future<Project?> findById(int id) async {
    final row = await _database
        .customSelect(
          '''
      SELECT id, name, version, default_material, estimated_weight,
             print_minutes, infill_percent, layer_height, nozzle_size,
             suggested_price, file_path, notes, active
      FROM projects WHERE id = ? LIMIT 1
      ''',
          variables: [Variable<int>(id)],
          readsFrom: const {},
        )
        .getSingleOrNull();
    return row == null ? null : Project.fromMap(row.data);
  }

  Future<int> count() async {
    final row = await _database
        .customSelect(
          'SELECT COUNT(*) AS total FROM projects WHERE active = 1',
          readsFrom: const {},
        )
        .getSingle();
    return row.read<int>('total');
  }

  Future<void> save({
    int? id,
    required String name,
    required String version,
    required String defaultMaterial,
    required double estimatedWeight,
    required int printMinutes,
    required double infillPercent,
    required double layerHeight,
    required double nozzleSize,
    required double suggestedPrice,
    required String filePath,
    required String notes,
    required bool active,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final activeValue = active ? 1 : 0;

    if (id == null) {
      await _database.customStatement(
        '''
        INSERT INTO projects
          (name, version, default_material, estimated_weight, print_minutes,
           infill_percent, layer_height, nozzle_size, suggested_price,
           file_path, notes, active, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          name,
          version,
          defaultMaterial,
          estimatedWeight,
          printMinutes,
          infillPercent,
          layerHeight,
          nozzleSize,
          suggestedPrice,
          filePath,
          notes,
          activeValue,
          now,
          now,
        ],
      );
      return;
    }

    await _database.customStatement(
      '''
      UPDATE projects
      SET name = ?, version = ?, default_material = ?, estimated_weight = ?,
          print_minutes = ?, infill_percent = ?, layer_height = ?,
          nozzle_size = ?, suggested_price = ?, file_path = ?, notes = ?,
          active = ?, updated_at = ?
      WHERE id = ?
      ''',
      [
        name,
        version,
        defaultMaterial,
        estimatedWeight,
        printMinutes,
        infillPercent,
        layerHeight,
        nozzleSize,
        suggestedPrice,
        filePath,
        notes,
        activeValue,
        now,
        id,
      ],
    );
  }

  Future<void> delete(int id) async {
    await _database.customStatement('DELETE FROM projects WHERE id = ?', [id]);
  }
}
