import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../domain/printer.dart';

final printerRepositoryProvider = Provider<PrinterRepository>((ref) {
  return PrinterRepository(ref.watch(appDatabaseProvider));
});

final printersProvider = FutureProvider<List<Printer>>((ref) {
  return ref.watch(printerRepositoryProvider).findAll();
});

final printerCountProvider = FutureProvider<int>((ref) {
  return ref.watch(printerRepositoryProvider).count();
});

final printerByIdProvider = FutureProvider.family<Printer?, int>((ref, id) {
  return ref.watch(printerRepositoryProvider).findById(id);
});

class PrinterRepository {
  PrinterRepository(this._database);

  final AppDatabase _database;

  Future<List<Printer>> findAll() async {
    final rows = await _database.customSelect('''
      SELECT id, name, manufacturer, model, serial_number, nozzle_size,
             purchase_price, printed_hours, maintenance_interval,
             last_maintenance_hours, active, notes
      FROM printers
      ORDER BY name COLLATE NOCASE
      ''', readsFrom: const {}).get();
    return rows.map((row) => Printer.fromMap(row.data)).toList();
  }

  Future<Printer?> findById(int id) async {
    final row = await _database
        .customSelect(
          '''
      SELECT id, name, manufacturer, model, serial_number, nozzle_size,
             purchase_price, printed_hours, maintenance_interval,
             last_maintenance_hours, active, notes
      FROM printers WHERE id = ? LIMIT 1
      ''',
          variables: [Variable<int>(id)],
          readsFrom: const {},
        )
        .getSingleOrNull();
    return row == null ? null : Printer.fromMap(row.data);
  }

  Future<int> count() async {
    final row = await _database
        .customSelect(
          'SELECT COUNT(*) AS total FROM printers WHERE active = 1',
          readsFrom: const {},
        )
        .getSingle();
    return row.read<int>('total');
  }

  Future<void> save({
    int? id,
    required String name,
    required String manufacturer,
    required String model,
    required String serialNumber,
    required double nozzleSize,
    required double purchasePrice,
    required double printedHours,
    required double maintenanceInterval,
    required double lastMaintenanceHours,
    required bool active,
    required String notes,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final activeValue = active ? 1 : 0;

    if (id == null) {
      await _database.customStatement(
        '''
        INSERT INTO printers
          (name, manufacturer, model, serial_number, nozzle_size, purchase_price,
           printed_hours, maintenance_interval, last_maintenance_hours,
           active, notes, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          name,
          manufacturer,
          model,
          serialNumber,
          nozzleSize,
          purchasePrice,
          printedHours,
          maintenanceInterval,
          lastMaintenanceHours,
          activeValue,
          notes,
          now,
          now,
        ],
      );
      return;
    }

    await _database.customStatement(
      '''
      UPDATE printers
      SET name = ?, manufacturer = ?, model = ?, serial_number = ?,
          nozzle_size = ?, purchase_price = ?, printed_hours = ?,
          maintenance_interval = ?, last_maintenance_hours = ?,
          active = ?, notes = ?, updated_at = ?
      WHERE id = ?
      ''',
      [
        name,
        manufacturer,
        model,
        serialNumber,
        nozzleSize,
        purchasePrice,
        printedHours,
        maintenanceInterval,
        lastMaintenanceHours,
        activeValue,
        notes,
        now,
        id,
      ],
    );
  }

  Future<void> delete(int id) async {
    await _database.customStatement('DELETE FROM printers WHERE id = ?', [id]);
  }
}
