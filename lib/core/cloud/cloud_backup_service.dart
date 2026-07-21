import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/app_database.dart';

class CloudBackupService {
  CloudBackupService(this._database, this._supabase);

  final AppDatabase _database;
  final SupabaseClient _supabase;

  static const _tables = <String>[
    'business_settings',
    'customers',
    'filaments',
    'filament_movements',
    'printers',
    'printer_maintenances',
    'projects',
    'products',
    'product_images',
    'product_files',
    'product_versions',
    'quotes',
    'quote_items',
    'production_orders',
    'invoices',
    'financial_entries',
    'cash_transactions',
  ];

  Future<void> uploadSnapshot() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw StateError('Usuário não autenticado.');

    final data = <String, Object?>{};
    for (final table in _tables) {
      final rows = await _database.customSelect('SELECT * FROM $table').get();
      data[table] = rows.map((row) => row.data).toList();
    }

    await _supabase.from('erp_snapshots').upsert({
      'owner_id': user.id,
      'payload': data,
      'app_version': '1.1.0',
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'owner_id');
  }

  Future<DateTime?> lastCloudUpdate() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    final row = await _supabase
        .from('erp_snapshots')
        .select('updated_at')
        .eq('owner_id', user.id)
        .maybeSingle();
    final value = row?['updated_at'] as String?;
    return value == null ? null : DateTime.tryParse(value)?.toLocal();
  }

  Future<void> restoreLatestSnapshot() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw StateError('Usuário não autenticado.');

    final row = await _supabase
        .from('erp_snapshots')
        .select('payload')
        .eq('owner_id', user.id)
        .maybeSingle();
    if (row == null) throw StateError('Nenhum backup encontrado na nuvem.');

    final raw = row['payload'];
    final payload = raw is String
        ? jsonDecode(raw) as Map<String, dynamic>
        : Map<String, dynamic>.from(raw as Map);

    await _database.transaction(() async {
      await _database.customStatement('PRAGMA foreign_keys = OFF');
      try {
        for (final table in _tables.reversed) {
          await _database.customStatement('DELETE FROM $table');
        }
        for (final table in _tables) {
          final rows = (payload[table] as List?) ?? const [];
          for (final rawRow in rows) {
            final row = Map<String, dynamic>.from(rawRow as Map);
            if (row.isEmpty) continue;
            final columns = row.keys.toList();
            final placeholders = List.filled(columns.length, '?').join(',');
            final quotedColumns = columns
                .map((column) => '"$column"')
                .join(',');
            await _database.customStatement(
              'INSERT INTO $table ($quotedColumns) VALUES ($placeholders)',
              columns.map((column) => row[column]).toList(),
            );
          }
        }
      } finally {
        await _database.customStatement('PRAGMA foreign_keys = ON');
      }
    });
  }
}
