import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../domain/printer_maintenance.dart';

final printerMaintenanceRepositoryProvider =
    Provider<PrinterMaintenanceRepository>((ref) {
      return PrinterMaintenanceRepository(ref.watch(appDatabaseProvider));
    });

final printerMaintenancesProvider =
    FutureProvider.family<List<PrinterMaintenance>, int>((ref, printerId) {
      return ref
          .watch(printerMaintenanceRepositoryProvider)
          .findByPrinter(printerId);
    });

class PrinterMaintenanceRepository {
  PrinterMaintenanceRepository(this._database);

  final AppDatabase _database;

  Future<List<PrinterMaintenance>> findByPrinter(int printerId) async {
    final rows = await _database
        .customSelect(
          '''
      SELECT id, printer_id, type, description, printer_hours, cost,
             performed_at, next_due_hours, notes
      FROM printer_maintenances
      WHERE printer_id = ?
      ORDER BY performed_at DESC, id DESC
      ''',
          variables: [Variable<int>(printerId)],
          readsFrom: const {},
        )
        .get();
    return rows.map((row) => PrinterMaintenance.fromMap(row.data)).toList();
  }

  Future<void> register({
    required int printerId,
    required String type,
    required String description,
    required double printerHours,
    required double cost,
    required DateTime performedAt,
    required double? nextDueHours,
    required String notes,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _database.transaction(() async {
      await _database.customStatement(
        '''
        INSERT INTO printer_maintenances
          (printer_id, type, description, printer_hours, cost, performed_at,
           next_due_hours, notes, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          printerId,
          type,
          description,
          printerHours,
          cost,
          performedAt.millisecondsSinceEpoch,
          nextDueHours,
          notes,
          now,
        ],
      );
      await _database.customStatement(
        '''
        UPDATE printers
        SET printed_hours = CASE
              WHEN printed_hours < ? THEN ?
              ELSE printed_hours
            END,
            last_maintenance_hours = ?,
            updated_at = ?
        WHERE id = ?
        ''',
        [printerHours, printerHours, printerHours, now, printerId],
      );
    });
  }

  Future<void> delete(int id) async {
    await _database.customStatement(
      'DELETE FROM printer_maintenances WHERE id = ?',
      [id],
    );
  }
}
