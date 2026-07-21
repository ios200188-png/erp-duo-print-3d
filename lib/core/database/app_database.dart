import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw StateError('AppDatabase precisa ser inicializado no main.dart.');
});

class AppDatabase extends GeneratedDatabase {
  AppDatabase() : super(driftDatabase(name: 'erp_duo_print_3d'));

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

    await _ensureColumn(
      'filaments',
      'reserved_weight',
      'REAL NOT NULL DEFAULT 0',
    );

    await customStatement('''
      CREATE TABLE IF NOT EXISTS filament_movements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        filament_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        quantity REAL NOT NULL,
        balance_before REAL NOT NULL,
        balance_after REAL NOT NULL,
        unit_cost REAL NOT NULL DEFAULT 0,
        reason TEXT NOT NULL DEFAULT '',
        production_order_id INTEGER,
        created_at INTEGER NOT NULL,
        FOREIGN KEY(filament_id) REFERENCES filaments(id)
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
      CREATE TABLE IF NOT EXISTS printer_maintenances (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        printer_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        printer_hours REAL NOT NULL DEFAULT 0,
        cost REAL NOT NULL DEFAULT 0,
        performed_at INTEGER NOT NULL,
        next_due_hours REAL,
        notes TEXT NOT NULL DEFAULT '',
        created_at INTEGER NOT NULL,
        FOREIGN KEY(printer_id) REFERENCES printers(id)
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
        maintenance_percent REAL NOT NULL DEFAULT 3,
        failure_percent REAL NOT NULL DEFAULT 5,
        ideal_margin_percent REAL NOT NULL DEFAULT 60,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Migra primeiro as instalações antigas. O INSERT abaixo usa
    // maintenance_percent e falhava antes do runApp quando a coluna ainda
    // não existia no banco já instalado.
    await _ensureColumn(
      'business_settings',
      'maintenance_percent',
      'REAL NOT NULL DEFAULT 3',
    );

    await customStatement('''
      INSERT OR IGNORE INTO business_settings (
        id, company_name, whatsapp, kwh_price, printer_power_w,
        labor_hour, machine_hour, packaging_cost, maintenance_percent,
        failure_percent, ideal_margin_percent, updated_at
      ) VALUES (1, 'Duo Print 3D', '', 0.85, 120, 20, 3, 1.5, 3, 5, 60, 0)
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
    await _ensureColumn(
      'business_settings',
      'default_observation',
      "TEXT NOT NULL DEFAULT ''",
    );
    await customStatement('''
      CREATE TABLE IF NOT EXISTS products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT '',
        description TEXT NOT NULL DEFAULT '',
        filament_id INTEGER,
        printer_id INTEGER,
        color TEXT NOT NULL DEFAULT '',
        estimated_weight REAL NOT NULL DEFAULT 0,
        print_minutes INTEGER NOT NULL DEFAULT 0,
        labor_minutes INTEGER NOT NULL DEFAULT 0,
        layer_height REAL NOT NULL DEFAULT 0.20,
        infill_percent REAL NOT NULL DEFAULT 15,
        wall_count INTEGER NOT NULL DEFAULT 2,
        supports INTEGER NOT NULL DEFAULT 0,
        nozzle_size REAL NOT NULL DEFAULT 0.4,
        packaging_cost REAL NOT NULL DEFAULT 0,
        additional_cost REAL NOT NULL DEFAULT 0,
        total_cost REAL NOT NULL DEFAULT 0,
        suggested_price REAL NOT NULL DEFAULT 0,
        active INTEGER NOT NULL DEFAULT 1,
        notes TEXT NOT NULL DEFAULT '',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY(filament_id) REFERENCES filaments(id),
        FOREIGN KEY(printer_id) REFERENCES printers(id)
      )
    ''');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS product_images (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        file_path TEXT NOT NULL,
        caption TEXT NOT NULL DEFAULT '',
        is_primary INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE CASCADE
      )
    ''');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS product_files (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        file_type TEXT NOT NULL,
        file_name TEXT NOT NULL,
        file_path TEXT NOT NULL,
        version TEXT NOT NULL DEFAULT '',
        notes TEXT NOT NULL DEFAULT '',
        created_at INTEGER NOT NULL,
        FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE CASCADE
      )
    ''');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS product_versions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        version TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        weight REAL NOT NULL DEFAULT 0,
        print_minutes INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE CASCADE
      )
    ''');

    await _ensureColumn(
      'product_images',
      'caption',
      "TEXT NOT NULL DEFAULT ''",
    );
    await _ensureColumn('product_files', 'version', "TEXT NOT NULL DEFAULT ''");
    await _ensureColumn(
      'product_versions',
      'weight',
      'REAL NOT NULL DEFAULT 0',
    );
    await _ensureColumn(
      'product_versions',
      'print_minutes',
      'INTEGER NOT NULL DEFAULT 0',
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
        maintenance_cost REAL NOT NULL DEFAULT 0,
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

    await _ensureColumn('quotes', 'product_id', 'INTEGER');
    await _ensureColumn(
      'quotes',
      'maintenance_cost',
      'REAL NOT NULL DEFAULT 0',
    );
    await _ensureColumn('quotes', 'subtotal', 'REAL NOT NULL DEFAULT 0');
    await _ensureColumn(
      'quotes',
      'discount_type',
      "TEXT NOT NULL DEFAULT 'Percentual'",
    );
    await _ensureColumn('quotes', 'discount_value', 'REAL NOT NULL DEFAULT 0');
    await _ensureColumn('quotes', 'discount_amount', 'REAL NOT NULL DEFAULT 0');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS quote_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        quote_id INTEGER NOT NULL,
        product_id INTEGER,
        project_id INTEGER NOT NULL,
        filament_id INTEGER NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        quantity INTEGER NOT NULL DEFAULT 1,
        labor_minutes INTEGER NOT NULL DEFAULT 0,
        additional_cost REAL NOT NULL DEFAULT 0,
        material_cost REAL NOT NULL DEFAULT 0,
        energy_cost REAL NOT NULL DEFAULT 0,
        machine_cost REAL NOT NULL DEFAULT 0,
        labor_cost REAL NOT NULL DEFAULT 0,
        packaging_cost REAL NOT NULL DEFAULT 0,
        maintenance_cost REAL NOT NULL DEFAULT 0,
        failure_cost REAL NOT NULL DEFAULT 0,
        total_cost REAL NOT NULL DEFAULT 0,
        margin_percent REAL NOT NULL DEFAULT 0,
        unit_price REAL NOT NULL DEFAULT 0,
        total_price REAL NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY(quote_id) REFERENCES quotes(id) ON DELETE CASCADE,
        FOREIGN KEY(product_id) REFERENCES products(id),
        FOREIGN KEY(project_id) REFERENCES projects(id),
        FOREIGN KEY(filament_id) REFERENCES filaments(id)
      )
    ''');

    await customStatement('''
      INSERT INTO quote_items (
        quote_id, product_id, project_id, filament_id, description, quantity,
        labor_minutes, additional_cost, material_cost, energy_cost,
        machine_cost, labor_cost, packaging_cost, maintenance_cost,
        failure_cost, total_cost, margin_percent, unit_price, total_price,
        created_at, updated_at
      )
      SELECT q.id, q.product_id, q.project_id, q.filament_id,
             COALESCE(p.name, pr.name, 'Item do orçamento'), q.quantity,
             q.labor_minutes, q.additional_cost, q.material_cost, q.energy_cost,
             q.machine_cost, q.labor_cost, q.packaging_cost, q.maintenance_cost,
             q.failure_cost, q.total_cost, q.margin_percent,
             CASE WHEN q.quantity > 0 THEN q.sale_price / q.quantity ELSE q.sale_price END,
             q.sale_price, q.created_at, q.updated_at
      FROM quotes q
      LEFT JOIN products p ON p.id = q.product_id
      LEFT JOIN projects pr ON pr.id = q.project_id
      WHERE NOT EXISTS (
        SELECT 1 FROM quote_items qi WHERE qi.quote_id = q.id
      )
    ''');

    await customStatement('''
      UPDATE quotes
      SET subtotal = sale_price
      WHERE subtotal = 0 AND sale_price > 0
    ''');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS production_orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        quote_id INTEGER,
        project_id INTEGER NOT NULL,
        printer_id INTEGER,
        quantity_planned INTEGER NOT NULL DEFAULT 1,
        quantity_produced INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'Aguardando',
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

    await _ensureColumn('production_orders', 'product_id', 'INTEGER');
    await _ensureColumn('production_orders', 'quote_item_id', 'INTEGER');
    await _ensureColumn('production_orders', 'filament_id', 'INTEGER');
    await _ensureColumn(
      'production_orders',
      'estimated_weight',
      'REAL NOT NULL DEFAULT 0',
    );
    await _ensureColumn(
      'production_orders',
      'actual_weight',
      'REAL NOT NULL DEFAULT 0',
    );
    await _ensureColumn(
      'production_orders',
      'estimated_minutes',
      'INTEGER NOT NULL DEFAULT 0',
    );
    await _ensureColumn(
      'production_orders',
      'actual_minutes',
      'INTEGER NOT NULL DEFAULT 0',
    );
    await _ensureColumn(
      'production_orders',
      'reserved_material_weight',
      'REAL NOT NULL DEFAULT 0',
    );
    await _ensureColumn(
      'production_orders',
      'estimated_material_cost',
      'REAL NOT NULL DEFAULT 0',
    );
    await _ensureColumn(
      'production_orders',
      'actual_material_cost',
      'REAL NOT NULL DEFAULT 0',
    );

    await customStatement("""
      UPDATE production_orders
      SET status = CASE status
        WHEN 'Planejada' THEN 'Aguardando'
        WHEN 'Finalizada' THEN 'Concluído'
        ELSE status
      END
      WHERE status IN ('Planejada', 'Finalizada')
    """);

    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_products_name ON products(name)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_product_images_product ON product_images(product_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_product_files_product ON product_files(product_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_product_versions_product ON product_versions(product_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_quotes_product ON quotes(product_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_production_product ON production_orders(product_id)',
    );

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

    await customStatement('''
      CREATE TABLE IF NOT EXISTS cash_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date INTEGER NOT NULL,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT '',
        finance_entry_id INTEGER UNIQUE,
        created_at INTEGER NOT NULL,
        FOREIGN KEY(finance_entry_id) REFERENCES financial_entries(id)
      )
    ''');

    await _ensureColumn(
      'financial_entries',
      'paid_amount',
      'REAL NOT NULL DEFAULT 0',
    );

    await customStatement('''
      UPDATE financial_entries
      SET paid_amount = amount
      WHERE status = 'Pago' AND paid_amount = 0
    ''');

    await _ensureColumn('quotes', 'delivery_date', 'INTEGER');
    await _ensureColumn(
      'quotes',
      'maintenance_cost',
      'REAL NOT NULL DEFAULT 0',
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
      'CREATE INDEX IF NOT EXISTS idx_products_name ON products(name COLLATE NOCASE)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_products_category ON products(category COLLATE NOCASE)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_products_active ON products(active)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_quotes_status ON quotes(status)',
    );
    await customStatement('DROP INDEX IF EXISTS idx_production_quote_unique');
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_production_quote_item_unique '
      'ON production_orders(quote_item_id) WHERE quote_item_id IS NOT NULL',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_quote_items_quote ON quote_items(quote_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_financial_due_date '
      'ON financial_entries(due_date)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_cash_transactions_date '
      'ON cash_transactions(date)',
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
      'CREATE INDEX IF NOT EXISTS idx_production_filament '
      'ON production_orders(filament_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_printers_maintenance '
      'ON printers(printed_hours, maintenance_interval)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_filament_movements_filament_date '
      'ON filament_movements(filament_id, created_at DESC)',
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
