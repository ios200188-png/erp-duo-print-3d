class PrinterMaintenance {
  const PrinterMaintenance({
    required this.id,
    required this.printerId,
    required this.type,
    required this.description,
    required this.printerHours,
    required this.cost,
    required this.performedAt,
    required this.nextDueHours,
    required this.notes,
  });

  final int id;
  final int printerId;
  final String type;
  final String description;
  final double printerHours;
  final double cost;
  final DateTime performedAt;
  final double? nextDueHours;
  final String notes;

  factory PrinterMaintenance.fromMap(Map<String, Object?> map) {
    return PrinterMaintenance(
      id: map['id']! as int,
      printerId: map['printer_id']! as int,
      type: map['type']! as String,
      description: map['description']! as String,
      printerHours: (map['printer_hours']! as num).toDouble(),
      cost: (map['cost']! as num).toDouble(),
      performedAt: DateTime.fromMillisecondsSinceEpoch(
        map['performed_at']! as int,
      ),
      nextDueHours: (map['next_due_hours'] as num?)?.toDouble(),
      notes: map['notes']! as String,
    );
  }
}
