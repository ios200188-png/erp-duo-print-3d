import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../domain/filament.dart';
import '../domain/filament_movement.dart';

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

final filamentByIdProvider = FutureProvider.family<Filament?, int>((ref, id) {
  return ref.watch(filamentRepositoryProvider).findById(id);
});

final filamentMovementsProvider =
    FutureProvider.family<List<FilamentMovement>, int?>((ref, filamentId) {
      return ref
          .watch(filamentRepositoryProvider)
          .findMovements(filamentId: filamentId);
    });

class FilamentRepository {
  FilamentRepository(this._database);

  final AppDatabase _database;

  static const _selectFields = '''
    id, name, material_type, brand, color, initial_weight, current_weight,
    reserved_weight, purchase_price, minimum_stock, supplier, notes
  ''';

  Future<List<Filament>> findAll() async {
    final rows = await _database
        .customSelect(
          'SELECT $_selectFields FROM filaments ORDER BY name COLLATE NOCASE',
          readsFrom: const {},
        )
        .get();
    return rows.map((row) => Filament.fromMap(row.data)).toList();
  }

  Future<Filament?> findById(int id) async {
    final row = await _database
        .customSelect(
          'SELECT $_selectFields FROM filaments WHERE id = ? LIMIT 1',
          variables: [Variable<int>(id)],
          readsFrom: const {},
        )
        .getSingleOrNull();
    return row == null ? null : Filament.fromMap(row.data);
  }

  Future<int> count() async {
    final row = await _database
        .customSelect(
          'SELECT COUNT(*) AS total FROM filaments',
          readsFrom: const {},
        )
        .getSingle();
    return row.read<int>('total');
  }

  Future<int> lowStockCount() async {
    final row = await _database.customSelect('''
      SELECT COUNT(*) AS total
      FROM filaments
      WHERE MAX(current_weight - reserved_weight, 0) <= minimum_stock
    ''', readsFrom: const {}).getSingle();
    return row.read<int>('total');
  }

  Future<List<FilamentMovement>> findMovements({int? filamentId}) async {
    final where = filamentId == null ? '' : 'WHERE m.filament_id = ?';
    final rows = await _database
        .customSelect(
          '''
      SELECT m.id, m.filament_id, f.name AS filament_name, m.type,
             m.quantity, m.balance_before, m.balance_after, m.unit_cost,
             m.reason, m.created_at
      FROM filament_movements m
      JOIN filaments f ON f.id = m.filament_id
      $where
      ORDER BY m.created_at DESC, m.id DESC
      LIMIT 500
      ''',
          variables: filamentId == null
              ? const []
              : [Variable<int>(filamentId)],
          readsFrom: const {},
        )
        .get();
    return rows.map((row) => FilamentMovement.fromMap(row.data)).toList();
  }

  Future<void> registerMovement({
    required int filamentId,
    required String type,
    required double quantity,
    required String reason,
    double unitCost = 0,
  }) async {
    if (quantity < 0) {
      throw ArgumentError('Informe um valor positivo.');
    }
    final filament = await findById(filamentId);
    if (filament == null) {
      throw StateError('Filamento não encontrado.');
    }

    final before = filament.currentWeight;
    late final double after;
    late final double movementQuantity;

    switch (type) {
      case 'Entrada':
        after = before + quantity;
        movementQuantity = quantity;
        break;
      case 'Saída':
        if (quantity > filament.availableWeight) {
          throw StateError('Estoque disponível insuficiente.');
        }
        after = before - quantity;
        movementQuantity = -quantity;
        break;
      case 'Ajuste':
        after = quantity;
        movementQuantity = after - before;
        break;
      default:
        throw ArgumentError('Tipo de movimentação inválido.');
    }

    if (after < filament.reservedWeight) {
      throw StateError('O saldo não pode ficar abaixo do material reservado.');
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    await _database.transaction(() async {
      await _database.customStatement(
        'UPDATE filaments SET current_weight = ?, updated_at = ? WHERE id = ?',
        [after, now, filamentId],
      );
      await _database.customStatement(
        '''
        INSERT INTO filament_movements
          (filament_id, type, quantity, balance_before, balance_after,
           unit_cost, reason, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          filamentId,
          type,
          movementQuantity,
          before,
          after,
          unitCost,
          reason,
          now,
        ],
      );
    });
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
      await _database.transaction(() async {
        await _database.customStatement(
          '''
          INSERT INTO filaments
            (name, material_type, brand, color, initial_weight, current_weight,
             purchase_price, minimum_stock, supplier, notes, created_at,
             updated_at)
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
        if (currentWeight > 0) {
          await _database.customStatement(
            '''
            INSERT INTO filament_movements
              (filament_id, type, quantity, balance_before, balance_after,
               unit_cost, reason, created_at)
            VALUES (last_insert_rowid(), 'Entrada', ?, 0, ?, ?,
                    'Estoque inicial', ?)
            ''',
            [
              currentWeight,
              currentWeight,
              initialWeight <= 0 ? 0 : purchasePrice / initialWeight,
              now,
            ],
          );
        }
      });
      return;
    }

    await _database.customStatement(
      '''
      UPDATE filaments
      SET name = ?, material_type = ?, brand = ?, color = ?,
          initial_weight = ?, purchase_price = ?, minimum_stock = ?,
          supplier = ?, notes = ?, updated_at = ?
      WHERE id = ?
      ''',
      [
        name,
        materialType,
        brand,
        color,
        initialWeight,
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
    await _database.transaction(() async {
      await _database.customStatement(
        'DELETE FROM filament_movements WHERE filament_id = ?',
        [id],
      );
      await _database.customStatement('DELETE FROM filaments WHERE id = ?', [
        id,
      ]);
    });
  }
}
