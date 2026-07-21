import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../domain/product.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(ref.watch(appDatabaseProvider));
});

final productsProvider = FutureProvider<List<Product>>((ref) {
  return ref.watch(productRepositoryProvider).findAll();
});

final productByIdProvider = FutureProvider.family<Product?, int>((ref, id) {
  return ref.watch(productRepositoryProvider).findById(id);
});

final productCountProvider = FutureProvider<int>((ref) {
  return ref.watch(productRepositoryProvider).count();
});

class ProductRepository {
  ProductRepository(this._database);

  final AppDatabase _database;

  static const _select = '''
    SELECT p.id, p.code, p.name, p.category, p.description,
           p.filament_id, COALESCE(f.name, '') AS filament_name,
           p.printer_id, COALESCE(pr.name, '') AS printer_name,
           p.color, p.estimated_weight, p.print_minutes, p.labor_minutes,
           p.layer_height, p.infill_percent, p.wall_count, p.supports,
           p.nozzle_size, p.packaging_cost, p.additional_cost, p.total_cost,
           p.suggested_price, p.active, p.notes
    FROM products p
    LEFT JOIN filaments f ON f.id = p.filament_id
    LEFT JOIN printers pr ON pr.id = p.printer_id
  ''';

  Future<List<Product>> findAll() async {
    final rows = await _database
        .customSelect(
          '$_select ORDER BY p.active DESC, p.name COLLATE NOCASE',
          readsFrom: const {},
        )
        .get();
    return rows.map((row) => Product.fromMap(row.data)).toList();
  }

  Future<Product?> findById(int id) async {
    final row = await _database
        .customSelect(
          '$_select WHERE p.id = ? LIMIT 1',
          variables: [Variable<int>(id)],
          readsFrom: const {},
        )
        .getSingleOrNull();
    return row == null ? null : Product.fromMap(row.data);
  }

  Future<int> count() async {
    final row = await _database
        .customSelect(
          'SELECT COUNT(*) AS total FROM products WHERE active = 1',
          readsFrom: const {},
        )
        .getSingle();
    return row.read<int>('total');
  }

  Future<void> save({
    int? id,
    required String code,
    required String name,
    required String category,
    required String description,
    required int? filamentId,
    required int? printerId,
    required String color,
    required double estimatedWeight,
    required int printMinutes,
    required int laborMinutes,
    required double layerHeight,
    required double infillPercent,
    required int wallCount,
    required bool supports,
    required double nozzleSize,
    required double packagingCost,
    required double additionalCost,
    required double totalCost,
    required double suggestedPrice,
    required bool active,
    required String notes,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final values = <Object?>[
      code,
      name,
      category,
      description,
      filamentId,
      printerId,
      color,
      estimatedWeight,
      printMinutes,
      laborMinutes,
      layerHeight,
      infillPercent,
      wallCount,
      supports ? 1 : 0,
      nozzleSize,
      packagingCost,
      additionalCost,
      totalCost,
      suggestedPrice,
      active ? 1 : 0,
      notes,
    ];

    if (id == null) {
      await _database.customStatement(
        '''
        INSERT INTO products
          (code, name, category, description, filament_id, printer_id, color,
           estimated_weight, print_minutes, labor_minutes, layer_height,
           infill_percent, wall_count, supports, nozzle_size, packaging_cost,
           additional_cost, total_cost, suggested_price, active, notes,
           created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
        [...values, now, now],
      );
      return;
    }

    await _database.customStatement(
      '''
      UPDATE products SET
        code = ?, name = ?, category = ?, description = ?, filament_id = ?,
        printer_id = ?, color = ?, estimated_weight = ?, print_minutes = ?,
        labor_minutes = ?, layer_height = ?, infill_percent = ?, wall_count = ?,
        supports = ?, nozzle_size = ?, packaging_cost = ?, additional_cost = ?,
        total_cost = ?, suggested_price = ?, active = ?, notes = ?, updated_at = ?
      WHERE id = ?
    ''',
      [...values, now, id],
    );
  }

  Future<void> delete(int id) async {
    await _database.customStatement('DELETE FROM products WHERE id = ?', [id]);
  }
}
