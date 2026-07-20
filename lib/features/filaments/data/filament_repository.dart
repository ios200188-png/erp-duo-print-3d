import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../domain/filament.dart';

final filamentRepositoryProvider = Provider<FilamentRepository>((ref) {
  return FilamentRepository(ref.watch(appDatabaseProvider));
});

final filamentsProvider = FutureProvider<List<Filament>>((ref) {
  return ref.watch(filamentRepositoryProvider).findAll();
});

final filamentCountProvider = FutureProvider<int>((ref) {
  return ref.watch(filamentRepositoryProvider).count();
});

final lowStockCountProvider = FutureProvider<int>((ref) {
  return ref.watch(filamentRepositoryProvider).lowStockCount();
});

final filamentByIdProvider =
    FutureProvider.family<Filament?, int>((ref, id) {
  return ref.watch(filamentRepositoryProvider).findById(id);
});

class FilamentRepository {
  FilamentRepository(this._database);

  final AppDatabase _database;

  Future<List<Filament>> findAll() async {
    final rows = await _database.customSelect(
      '''
      SELECT id, name, material_type, brand, color, initial_weight,
             current_weight, purchase_price, minimum_stock, supplier, notes
      FROM filaments
      ORDER BY name COLLATE NOCASE
      ''',
      readsFrom: const {},
    ).get();

    return rows.map((row) => Filament.fromMap(row.data)).toList();
  }

  Future<Filament?> findById(int id) async {
    final row = await _database.customSelect(
      '''
      SELECT id, name, material_type, brand, color, initial_weight,
             current_weight, purchase_price, minimum_stock, supplier, notes
      FROM filaments WHERE id = ? LIMIT 1
      ''',
      variables: [Variable<int>(id)],
      readsFrom: const {},
    ).getSingleOrNull();

    return row == null ? null : Filament.fromMap(row.data);
  }

  Future<int> count() async {
    final row = await _database.customSelect(
      'SELECT COUNT(*) AS total FROM filaments',
      readsFrom: const {},
    ).getSingle();
    return row.read<int>('total');
  }

  Future<int> lowStockCount() async {
    final row = await _database.customSelect(
      '''
      SELECT COUNT(*) AS total
      FROM filaments
      WHERE current_weight <= minimum_stock
      ''',
      readsFrom: const {},
    ).getSingle();
    return row.read<int>('total');
  }

  Future<void> save({
    int? id,
    required String name,
    required String materialType,
    required String brand,
    required String color,
    required double initialWeight,
    required double currentWeight,
    required double purchasePrice,
    required double minimumStock,
    required String supplier,
    required String notes,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    if (id == null) {
      await _database.customStatement(
        '''
        INSERT INTO filaments
          (name, material_type, brand, color, initial_weight, current_weight,
           purchase_price, minimum_stock, supplier, notes, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          name,
          materialType,
          brand,
          color,
          initialWeight,
          currentWeight,
          purchasePrice,
          minimumStock,
          supplier,
          notes,
          now,
          now,
        ],
      );
      return;
    }

    await _database.customStatement(
      '''
      UPDATE filaments
      SET name = ?, material_type = ?, brand = ?, color = ?,
          initial_weight = ?, current_weight = ?, purchase_price = ?,
          minimum_stock = ?, supplier = ?, notes = ?, updated_at = ?
      WHERE id = ?
      ''',
      [
        name,
        materialType,
        brand,
        color,
        initialWeight,
        currentWeight,
        purchasePrice,
        minimumStock,
        supplier,
        notes,
        now,
        id,
      ],
    );
  }

  Future<void> delete(int id) async {
    await _database.customStatement('DELETE FROM filaments WHERE id = ?', [id]);
  }
}
