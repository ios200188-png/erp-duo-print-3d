import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../domain/customer.dart';

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository(ref.watch(appDatabaseProvider));
});

final customersProvider = FutureProvider<List<Customer>>((ref) async {
  return ref.watch(customerRepositoryProvider).findAll();
});

final customerCountProvider = FutureProvider<int>((ref) async {
  return ref.watch(customerRepositoryProvider).count();
});

final customerByIdProvider =
    FutureProvider.family<Customer?, int>((ref, id) async {
  return ref.watch(customerRepositoryProvider).findById(id);
});

class CustomerRepository {
  CustomerRepository(this._database);

  final AppDatabase _database;

  Future<List<Customer>> findAll({String search = ''}) async {
    final normalized = search.trim();
    final variables = <Variable<Object>>[];
    var sql = '''
      SELECT id, name, phone, email, document, notes, created_at, updated_at
      FROM customers
    ''';

    if (normalized.isNotEmpty) {
      sql += '''
        WHERE name LIKE ? OR phone LIKE ? OR email LIKE ? OR document LIKE ?
      ''';
      final value = '%$normalized%';
      variables.addAll([
        Variable<String>(value),
        Variable<String>(value),
        Variable<String>(value),
        Variable<String>(value),
      ]);
    }

    sql += ' ORDER BY name COLLATE NOCASE';

    final rows = await _database.customSelect(
      sql,
      variables: variables,
      readsFrom: const {},
    ).get();

    return rows.map((row) => Customer.fromMap(row.data)).toList();
  }

  Future<Customer?> findById(int id) async {
    final row = await _database.customSelect(
      '''
      SELECT id, name, phone, email, document, notes, created_at, updated_at
      FROM customers WHERE id = ? LIMIT 1
      ''',
      variables: [Variable<int>(id)],
      readsFrom: const {},
    ).getSingleOrNull();

    return row == null ? null : Customer.fromMap(row.data);
  }

  Future<int> count() async {
    final row = await _database.customSelect(
      'SELECT COUNT(*) AS total FROM customers',
      readsFrom: const {},
    ).getSingle();
    return row.read<int>('total');
  }

  Future<void> save({
    int? id,
    required String name,
    required String phone,
    required String email,
    required String document,
    required String notes,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    if (id == null) {
      await _database.customStatement(
        '''
        INSERT INTO customers
          (name, phone, email, document, notes, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        ''',
        [name, phone, email, document, notes, now, now],
      );
      return;
    }

    await _database.customStatement(
      '''
      UPDATE customers
      SET name = ?, phone = ?, email = ?, document = ?, notes = ?, updated_at = ?
      WHERE id = ?
      ''',
      [name, phone, email, document, notes, now, id],
    );
  }

  Future<void> delete(int id) async {
    await _database.customStatement(
      'DELETE FROM customers WHERE id = ?',
      [id],
    );
  }
}
