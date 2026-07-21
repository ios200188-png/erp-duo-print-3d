class FilamentMovement {
  const FilamentMovement({
    required this.id,
    required this.filamentId,
    required this.filamentName,
    required this.type,
    required this.quantity,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.unitCost,
    required this.reason,
    required this.createdAt,
  });

  final int id;
  final int filamentId;
  final String filamentName;
  final String type;
  final double quantity;
  final double balanceBefore;
  final double balanceAfter;
  final double unitCost;
  final String reason;
  final DateTime createdAt;

  bool get isEntry => quantity > 0;

  factory FilamentMovement.fromMap(Map<String, Object?> map) {
    return FilamentMovement(
      id: map['id']! as int,
      filamentId: map['filament_id']! as int,
      filamentName: (map['filament_name'] as String?) ?? '',
      type: map['type']! as String,
      quantity: (map['quantity']! as num).toDouble(),
      balanceBefore: (map['balance_before']! as num).toDouble(),
      balanceAfter: (map['balance_after']! as num).toDouble(),
      unitCost: (map['unit_cost']! as num).toDouble(),
      reason: map['reason']! as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']! as int),
    );
  }
}
