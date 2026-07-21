class ProductionScheduleItem {
  const ProductionScheduleItem({
    required this.id,
    required this.projectName,
    required this.printerName,
    required this.status,
    required this.priority,
    required this.start,
    required this.end,
    required this.estimatedMinutes,
    required this.isConflict,
  });

  final int id;
  final String projectName;
  final String printerName;
  final String status;
  final String priority;
  final DateTime start;
  final DateTime end;
  final int estimatedMinutes;
  final bool isConflict;

  bool get isOverdue =>
      status != 'Concluído' &&
      status != 'Cancelada' &&
      end.isBefore(DateTime.now());
}

class ProductionScheduleRange {
  const ProductionScheduleRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  @override
  bool operator ==(Object other) =>
      other is ProductionScheduleRange &&
      other.start == start &&
      other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}
