class ProductionOrder {
  const ProductionOrder({
    required this.id,
    required this.projectName,
    required this.printerName,
    required this.filamentName,
    required this.quantityPlanned,
    required this.quantityProduced,
    required this.status,
    required this.priority,
    required this.scheduledDate,
    required this.estimatedWeight,
    required this.actualWeight,
    required this.estimatedMinutes,
    required this.actualMinutes,
    required this.reservedMaterialWeight,
    required this.estimatedMaterialCost,
    required this.actualMaterialCost,
    required this.notes,
  });

  final int id;
  final String projectName;
  final String printerName;
  final String filamentName;
  final int quantityPlanned;
  final int quantityProduced;
  final String status;
  final String priority;
  final DateTime? scheduledDate;
  final double estimatedWeight;
  final double actualWeight;
  final int estimatedMinutes;
  final int actualMinutes;
  final double reservedMaterialWeight;
  final double estimatedMaterialCost;
  final double actualMaterialCost;
  final String notes;

  double get progress {
    if (quantityPlanned <= 0) return 0;
    return (quantityProduced / quantityPlanned).clamp(0, 1).toDouble();
  }

  bool get isFinished => status == 'Concluído' || status == 'Cancelada';

  bool get isOverdue {
    final dueDate = scheduledDate;
    if (dueDate == null || isFinished) return false;
    final limit = DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day,
      23,
      59,
      59,
    );
    return DateTime.now().isAfter(limit);
  }

  double get weightDifference => actualWeight - estimatedWeight;
  int get minutesDifference => actualMinutes - estimatedMinutes;

  factory ProductionOrder.fromMap(Map<String, Object?> map) {
    final rawDate = map['scheduled_date'] as int?;
    return ProductionOrder(
      id: map['id']! as int,
      projectName: map['project_name']! as String,
      printerName: (map['printer_name'] as String?) ?? 'Não definida',
      filamentName: (map['filament_name'] as String?) ?? 'Não definido',
      quantityPlanned: map['quantity_planned']! as int,
      quantityProduced: map['quantity_produced']! as int,
      status: map['status']! as String,
      priority: map['priority']! as String,
      scheduledDate: rawDate == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(rawDate),
      estimatedWeight: ((map['estimated_weight'] as num?) ?? 0).toDouble(),
      actualWeight: ((map['actual_weight'] as num?) ?? 0).toDouble(),
      estimatedMinutes: ((map['estimated_minutes'] as num?) ?? 0).toInt(),
      actualMinutes: ((map['actual_minutes'] as num?) ?? 0).toInt(),
      reservedMaterialWeight: ((map['reserved_material_weight'] as num?) ?? 0)
          .toDouble(),
      estimatedMaterialCost: ((map['estimated_material_cost'] as num?) ?? 0)
          .toDouble(),
      actualMaterialCost: ((map['actual_material_cost'] as num?) ?? 0)
          .toDouble(),
      notes: map['notes']! as String,
    );
  }
}
