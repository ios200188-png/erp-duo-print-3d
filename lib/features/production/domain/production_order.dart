class ProductionOrder {
  const ProductionOrder({
    required this.id,
    required this.projectName,
    required this.printerName,
    required this.quantityPlanned,
    required this.quantityProduced,
    required this.status,
    required this.priority,
    required this.scheduledDate,
    required this.notes,
  });

  final int id;
  final String projectName;
  final String printerName;
  final int quantityPlanned;
  final int quantityProduced;
  final String status;
  final String priority;
  final DateTime? scheduledDate;
  final String notes;

  double get progress {
    if (quantityPlanned <= 0) return 0;
    return (quantityProduced / quantityPlanned).clamp(0, 1);
  }

  factory ProductionOrder.fromMap(Map<String, Object?> map) {
    final rawDate = map['scheduled_date'] as int?;
    return ProductionOrder(
      id: map['id']! as int,
      projectName: map['project_name']! as String,
      printerName: (map['printer_name'] as String?) ?? 'Não definida',
      quantityPlanned: map['quantity_planned']! as int,
      quantityProduced: map['quantity_produced']! as int,
      status: map['status']! as String,
      priority: map['priority']! as String,
      scheduledDate: rawDate == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(rawDate),
      notes: map['notes']! as String,
    );
  }
}
