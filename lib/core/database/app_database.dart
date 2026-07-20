import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw StateError('AppDatabase precisa ser inicializado no main.dart.');
});

class AppDatabase extends GeneratedDatabase {
  AppDatabase()
      : super(
          driftDatabase(
            name: 'erp_duo_print_3d',
          ),
        );

  @override
  int get schemaVersion => 1;

  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];

  Future<void> initialize() async {
    await customStatement('PRAGMA foreign_keys = ON');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL DEFAULT '',
        email TEXT NOT NULL DEFAULT '',
        document TEXT NOT NULL DEFAULT '',
        notes TEXT NOT NULL DEFAULT '',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS filaments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        material_type TEXT NOT NULL,
        brand TEXT NOT NULL DEFAULT '',
        color TEXT NOT NULL DEFAULT '',
        initial_weight REAL NOT NULL,
        current_weight REAL NOT NULL,
        purchase_price REAL NOT NULL,
        minimum_stock REAL NOT NULL DEFAULT 200,
        supplier TEXT NOT NULL DEFAULT '',
        purchase_date INTEGER,
        notes TEXT NOT NULL DEFAULT '',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS printers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        manufacturer TEXT NOT NULL DEFAULT '',
        model TEXT NOT NULL DEFAULT '',
        serial_number TEXT NOT NULL DEFAULT '',
        nozzle_size REAL NOT NULL DEFAULT 0.4,
        purchase_price REAL NOT NULL DEFAULT 0,
        printed_hours REAL NOT NULL DEFAULT 0,
        maintenance_interval REAL NOT NULL DEFAULT 500,
        last_maintenance_hours REAL NOT NULL DEFAULT 0,
        active INTEGER NOT NULL DEFAULT 1,
        notes TEXT NOT NULL DEFAULT '',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS projects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        version TEXT NOT NULL DEFAULT '',
        default_material TEXT NOT NULL DEFAULT '',
        estimated_weight REAL NOT NULL DEFAULT 0,
        print_minutes INTEGER NOT NULL DEFAULT 0,
        infill_percent REAL NOT NULL DEFAULT 15,
        layer_height REAL NOT NULL DEFAULT 0.20,
        nozzle_size REAL NOT NULL DEFAULT 0.4,
        suggested_price REAL NOT NULL DEFAULT 0,
        file_path TEXT NOT NULL DEFAULT '',
        notes TEXT NOT NULL DEFAULT '',
        active INTEGER NOT NULL DEFAULT 1,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS business_settings (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        company_name TEXT NOT NULL DEFAULT 'Duo Print 3D',
        whatsapp TEXT NOT NULL DEFAULT '',
        kwh_price REAL NOT NULL DEFAULT 0.85,
        printer_power_w REAL NOT NULL DEFAULT 120,
        labor_hour REAL NOT NULL DEFAULT 20,
        machine_hour REAL NOT NULL DEFAULT 3,
        packaging_cost REAL NOT NULL DEFAULT 1.5,
        failure_percent REAL NOT NULL DEFAULT 5,
        ideal_margin_percent REAL NOT NULL DEFAULT 60,
        updated_at INTEGER NOT NULL
      )
    ''');

    await customStatement('''
      INSERT OR IGNORE INTO business_settings (
        id, company_name, whatsapp, kwh_price, printer_power_w,
        labor_hour, machine_hour, packaging_cost, failure_percent,
        ideal_margin_percent, updated_at
      ) VALUES (1, 'Duo Print 3D', '', 0.85, 120, 20, 3, 1.5, 5, 60, 0)
    ''');

    await _ensureColumn(
      'business_settings',
      'document',
      "TEXT NOT NULL DEFAULT ''",
    );
    await _ensureColumn(
      'business_settings',
      'email',
      "TEXT NOT NULL DEFAULT ''",
    );
    await _ensureColumn(
      'business_settings',
      'address',
      "TEXT NOT NULL DEFAULT ''",
    );
    await _ensureColumn(
      'business_settings',
      'city',
      "TEXT NOT NULL DEFAULT ''",
    );

    await customStatement('''
      CREATE TABLE IF NOT EXISTS quotes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER NOT NULL,
        project_id INTEGER NOT NULL,
        filament_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 1,
        labor_minutes INTEGER NOT NULL DEFAULT 0,
        additional_cost REAL NOT NULL DEFAULT 0,
        material_cost REAL NOT NULL DEFAULT 0,
        energy_cost REAL NOT NULL DEFAULT 0,
        machine_cost REAL NOT NULL DEFAULT 0,
        labor_cost REAL NOT NULL DEFAULT 0,
        packaging_cost REAL NOT NULL DEFAULT 0,
        failure_cost REAL NOT NULL DEFAULT 0,
        total_cost REAL NOT NULL DEFAULT 0,
        margin_percent REAL NOT NULL DEFAULT 0,
        sale_price REAL NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'Rascunho',
        notes TEXT NOT NULL DEFAULT '',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY(customer_id) REFERENCES customers(id),
        FOREIGN KEY(project_id) REFERENCES projects(id),
        FOREIGN KEY(filament_id) REFERENCES filaments(id)
      )
    ''');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS production_orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        quote_id INTEGER,
        project_id INTEGER NOT NULL,
        printer_id INTEGER,
        quantity_planned INTEGER NOT NULL DEFAULT 1,
        quantity_produced INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'Planejada',
        priority TEXT NOT NULL DEFAULT 'Normal',
        scheduled_date INTEGER,
        started_at INTEGER,
        finished_at INTEGER,
        notes TEXT NOT NULL DEFAULT '',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY(quote_id) REFERENCES quotes(id),
        FOREIGN KEY(project_id) REFERENCES projects(id),
        FOREIGN KEY(printer_id) REFERENCES printers(id)
      )
    ''');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS financial_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT '',
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        due_date INTEGER NOT NULL,
        paid_date INTEGER,
        status TEXT NOT NULL DEFAULT 'Pendente',
        quote_id INTEGER,
        notes TEXT NOT NULL DEFAULT '',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY(quote_id) REFERENCES quotes(id)
      )
    ''');


    await _ensureColumn(
      'quotes',
      'delivery_date',
      'INTEGER',
    );

    await customStatement('''
      CREATE TABLE IF NOT EXISTS invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        quote_id INTEGER NOT NULL UNIQUE,
        payment_method TEXT NOT NULL,
        due_date INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'Emitida',
        notes TEXT NOT NULL DEFAULT '',
        issued_at INTEGER NOT NULL,
        paid_at INTEGER,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY(quote_id) REFERENCES quotes(id)
      )
    ''');

    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_quotes_status ON quotes(status)',
    );
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_production_quote_unique '
      'ON production_orders(quote_id) WHERE quote_id IS NOT NULL',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_financial_due_date '
      'ON financial_entries(due_date)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_invoices_status ON invoices(status)',
    );

    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_quotes_delivery_date '
      'ON quotes(delivery_date)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_production_scheduled_date '
      'ON production_orders(scheduled_date)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_printers_maintenance '
      'ON printers(printed_hours, maintenance_interval)',
    );
  }

  Future<void> _ensureColumn(
    String table,
    String column,
    String definition,
  ) async {
    final rows = await customSelect(
      'PRAGMA table_info($table)',
      readsFrom: const {},
    ).get();

    final exists = rows.any((row) => row.read<String>('name') == column);
    if (!exists) {
      await customStatement(
        'ALTER TABLE $table ADD COLUMN $column $definition',
      );
    }
  }
}
