import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../domain/production_order.dart';

final productionRepositoryProvider = Provider<ProductionRepository>((ref) {
  return ProductionRepository(ref.watch(appDatabaseProvider));
});

final productionOrdersProvider = FutureProvider<List<ProductionOrder>>((ref) {
  return ref.watch(productionRepositoryProvider).findAll();
});

final productionOpenCountProvider = FutureProvider<int>((ref) {
  return ref.watch(productionRepositoryProvider).openCount();
});

class ProductionRepository {
  ProductionRepository(this._database);

  final AppDatabase _database;

  Future<List<ProductionOrder>> findAll() async {
    final rows = await _database.customSelect('''
      SELECT po.id, p.name AS project_name, pr.name AS printer_name,
             f.name AS filament_name, po.quantity_planned,
             po.quantity_produced, po.status, po.priority,
             po.scheduled_date, po.estimated_weight, po.actual_weight,
             po.estimated_minutes, po.actual_minutes,
             po.reserved_material_weight, po.estimated_material_cost,
             po.actual_material_cost, po.notes
      FROM production_orders po
      INNER JOIN projects p ON p.id = po.project_id
      LEFT JOIN printers pr ON pr.id = po.printer_id
      LEFT JOIN filaments f ON f.id = po.filament_id
      ORDER BY
        CASE po.status
          WHEN 'Imprimindo' THEN 1
          WHEN 'Preparando' THEN 2
          WHEN 'Aguardando' THEN 3
          WHEN 'Acabamento' THEN 4
          WHEN 'Pausada' THEN 5
          ELSE 6
        END,
        po.created_at DESC
      ''', readsFrom: const {}).get();

    return rows.map((row) => ProductionOrder.fromMap(row.data)).toList();
  }

  Future<int> openCount() async {
    final row = await _database.customSelect('''
      SELECT COUNT(*) AS total
      FROM production_orders
      WHERE status NOT IN ('Concluído', 'Cancelada')
      ''', readsFrom: const {}).getSingle();
    return row.read<int>('total');
  }

  Future<void> save({
    required int projectId,
    int? printerId,
    int? filamentId,
    required int quantityPlanned,
    required int quantityProduced,
    required String status,
    required String priority,
    DateTime? scheduledDate,
    required double estimatedWeight,
    required int estimatedMinutes,
    required String notes,
  }) async {
    if (quantityPlanned <= 0) {
      throw ArgumentError('A quantidade planejada deve ser maior que zero.');
    }
    if (estimatedWeight < 0 || estimatedMinutes < 0) {
      throw ArgumentError('Peso e tempo previstos não podem ser negativos.');
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    double estimatedMaterialCost = 0;
    if (filamentId != null) {
      final filament = await _filamentData(filamentId);
      estimatedMaterialCost = estimatedWeight * filament.costPerGram;
    }

    await _database.customStatement(
      '''
      INSERT INTO production_orders (
        project_id, printer_id, filament_id, quantity_planned,
        quantity_produced, status, priority, scheduled_date,
        estimated_weight, estimated_minutes, estimated_material_cost,
        notes, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        projectId,
        printerId,
        filamentId,
        quantityPlanned,
        quantityProduced,
        status == 'Imprimindo' ? 'Preparando' : status,
        priority,
        scheduledDate?.millisecondsSinceEpoch,
        estimatedWeight,
        estimatedMinutes,
        estimatedMaterialCost,
        notes,
        now,
        now,
      ],
    );
  }

  Future<void> updateStatus(
    int id,
    String status, {
    int? quantityProduced,
    double? actualWeight,
    int? actualMinutes,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await _database.transaction(() async {
      final row = await _database
          .customSelect(
            '''
            SELECT id, quote_id, filament_id, status, estimated_weight,
                   reserved_material_weight, actual_weight
            FROM production_orders
            WHERE id = ? LIMIT 1
            ''',
            variables: [Variable<int>(id)],
            readsFrom: const {},
          )
          .getSingleOrNull();

      if (row == null) throw StateError('Ordem de produção não encontrada.');

      final previousStatus = row.read<String>('status');
      final filamentId = row.readNullable<int>('filament_id');
      final estimatedWeight = row.read<double>('estimated_weight');
      var reservedWeight = row.read<double>('reserved_material_weight');
      var finalActualWeight = actualWeight ?? row.read<double>('actual_weight');
      var actualMaterialCost = 0.0;

      final enteringPrint =
          status == 'Imprimindo' &&
          !const [
            'Imprimindo',
            'Acabamento',
            'Concluído',
          ].contains(previousStatus);

      if (enteringPrint) {
        if (filamentId == null) {
          throw StateError(
            'Selecione um filamento antes de iniciar a impressão.',
          );
        }
        if (estimatedWeight <= 0) {
          throw StateError(
            'Informe o peso previsto antes de iniciar a impressão.',
          );
        }
        final filament = await _filamentData(filamentId);
        if (estimatedWeight > filament.availableWeight) {
          throw StateError(
            'Estoque insuficiente. Disponível: '
            '${filament.availableWeight.toStringAsFixed(1)} g.',
          );
        }
        reservedWeight = estimatedWeight;
        await _database.customStatement(
          'UPDATE filaments SET reserved_weight = reserved_weight + ?, updated_at = ? WHERE id = ?',
          [reservedWeight, now, filamentId],
        );
        await _insertMovement(
          filamentId: filamentId,
          type: 'Reserva',
          quantity: reservedWeight,
          balanceBefore: filament.currentWeight,
          balanceAfter: filament.currentWeight,
          unitCost: filament.costPerGram,
          reason: 'Reserva para ordem #$id',
          productionOrderId: id,
          now: now,
        );
      }

      final leavingActiveProduction =
          const ['Imprimindo', 'Acabamento'].contains(previousStatus) &&
          const ['Aguardando', 'Preparando', 'Cancelada'].contains(status);

      if (leavingActiveProduction && filamentId != null && reservedWeight > 0) {
        final filament = await _filamentData(filamentId);
        await _database.customStatement(
          'UPDATE filaments SET reserved_weight = MAX(reserved_weight - ?, 0), updated_at = ? WHERE id = ?',
          [reservedWeight, now, filamentId],
        );
        await _insertMovement(
          filamentId: filamentId,
          type: 'Liberação',
          quantity: -reservedWeight,
          balanceBefore: filament.currentWeight,
          balanceAfter: filament.currentWeight,
          unitCost: filament.costPerGram,
          reason: 'Liberação da reserva da ordem #$id',
          productionOrderId: id,
          now: now,
        );
        reservedWeight = 0;
      }

      if (status == 'Concluído') {
        if (filamentId == null) {
          throw StateError('A ordem não possui filamento selecionado.');
        }
        if (finalActualWeight <= 0) finalActualWeight = estimatedWeight;
        if (finalActualWeight <= 0) {
          throw StateError('Informe o consumo real de filamento.');
        }

        final filament = await _filamentData(filamentId);
        final extraNeeded = (finalActualWeight - reservedWeight).clamp(
          0,
          double.infinity,
        );
        if (extraNeeded > filament.availableWeight) {
          throw StateError(
            'Estoque insuficiente para registrar o consumo real. '
            'Disponível adicional: ${filament.availableWeight.toStringAsFixed(1)} g.',
          );
        }
        if (finalActualWeight > filament.currentWeight) {
          throw StateError(
            'O consumo real é maior que o saldo físico do filamento.',
          );
        }

        final after = filament.currentWeight - finalActualWeight;
        actualMaterialCost = finalActualWeight * filament.costPerGram;
        await _database.customStatement(
          '''
          UPDATE filaments
          SET current_weight = ?,
              reserved_weight = MAX(reserved_weight - ?, 0),
              updated_at = ?
          WHERE id = ?
          ''',
          [after, reservedWeight, now, filamentId],
        );
        await _insertMovement(
          filamentId: filamentId,
          type: 'Consumo',
          quantity: -finalActualWeight,
          balanceBefore: filament.currentWeight,
          balanceAfter: after,
          unitCost: filament.costPerGram,
          reason: 'Consumo real da ordem #$id',
          productionOrderId: id,
          now: now,
        );
        reservedWeight = 0;
      }

      await _database.customStatement(
        '''
        UPDATE production_orders
        SET status = ?,
            quantity_produced = COALESCE(?, quantity_produced),
            actual_weight = CASE WHEN ? IS NULL THEN actual_weight ELSE ? END,
            actual_minutes = CASE WHEN ? IS NULL THEN actual_minutes ELSE ? END,
            actual_material_cost = CASE WHEN ? = 'Concluído' THEN ? ELSE actual_material_cost END,
            reserved_material_weight = ?,
            started_at = CASE
              WHEN ? = 'Imprimindo' THEN COALESCE(started_at, ?)
              ELSE started_at
            END,
            finished_at = CASE
              WHEN ? = 'Concluído' THEN ?
              WHEN ? <> 'Concluído' THEN NULL
              ELSE finished_at
            END,
            updated_at = ?
        WHERE id = ?
        ''',
        [
          status,
          quantityProduced,
          actualWeight,
          finalActualWeight,
          actualMinutes,
          actualMinutes,
          status,
          actualMaterialCost,
          reservedWeight,
          status,
          now,
          status,
          now,
          status,
          now,
          id,
        ],
      );

      if (status == 'Concluído') {
        final quoteId = row.readNullable<int>('quote_id');
        if (quoteId != null) {
          await _database.customStatement(
            "UPDATE quotes SET status = 'Produzido', updated_at = ? WHERE id = ?",
            [now, quoteId],
          );
        }
      }
    });
  }

  Future<void> delete(int id) async {
    final row = await _database
        .customSelect(
          'SELECT filament_id, reserved_material_weight FROM production_orders WHERE id = ? LIMIT 1',
          variables: [Variable<int>(id)],
          readsFrom: const {},
        )
        .getSingleOrNull();

    await _database.transaction(() async {
      if (row != null) {
        final filamentId = row.readNullable<int>('filament_id');
        final reserved = row.read<double>('reserved_material_weight');
        if (filamentId != null && reserved > 0) {
          await _database.customStatement(
            'UPDATE filaments SET reserved_weight = MAX(reserved_weight - ?, 0) WHERE id = ?',
            [reserved, filamentId],
          );
        }
      }
      await _database.customStatement(
        'DELETE FROM production_orders WHERE id = ?',
        [id],
      );
    });
  }

  Future<_FilamentData> _filamentData(int id) async {
    final row = await _database
        .customSelect(
          '''
          SELECT current_weight, reserved_weight, initial_weight, purchase_price
          FROM filaments WHERE id = ? LIMIT 1
          ''',
          variables: [Variable<int>(id)],
          readsFrom: const {},
        )
        .getSingleOrNull();
    if (row == null) throw StateError('Filamento não encontrado.');
    return _FilamentData(
      currentWeight: row.read<double>('current_weight'),
      reservedWeight: row.read<double>('reserved_weight'),
      initialWeight: row.read<double>('initial_weight'),
      purchasePrice: row.read<double>('purchase_price'),
    );
  }

  Future<void> _insertMovement({
    required int filamentId,
    required String type,
    required double quantity,
    required double balanceBefore,
    required double balanceAfter,
    required double unitCost,
    required String reason,
    required int productionOrderId,
    required int now,
  }) async {
    await _database.customStatement(
      '''
      INSERT INTO filament_movements
        (filament_id, type, quantity, balance_before, balance_after,
         unit_cost, reason, production_order_id, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        filamentId,
        type,
        quantity,
        balanceBefore,
        balanceAfter,
        unitCost,
        reason,
        productionOrderId,
        now,
      ],
    );
  }
}

class _FilamentData {
  const _FilamentData({
    required this.currentWeight,
    required this.reservedWeight,
    required this.initialWeight,
    required this.purchasePrice,
  });

  final double currentWeight;
  final double reservedWeight;
  final double initialWeight;
  final double purchasePrice;

  double get availableWeight =>
      (currentWeight - reservedWeight).clamp(0, double.infinity).toDouble();

  double get costPerGram =>
      initialWeight <= 0 ? 0 : purchasePrice / initialWeight;
}
