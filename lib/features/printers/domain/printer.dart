class Printer {
  const Printer({
    required this.id,
    required this.name,
    required this.manufacturer,
    required this.model,
    required this.serialNumber,
    required this.nozzleSize,
    required this.purchasePrice,
    required this.printedHours,
    required this.maintenanceInterval,
    required this.lastMaintenanceHours,
    required this.active,
    required this.notes,
  });

  final int id;
  final String name;
  final String manufacturer;
  final String model;
  final String serialNumber;
  final double nozzleSize;
  final double purchasePrice;
  final double printedHours;
  final double maintenanceInterval;
  final double lastMaintenanceHours;
  final bool active;
  final String notes;

  double get hoursUntilMaintenance {
    final value = maintenanceInterval - (printedHours - lastMaintenanceHours);
    return value < 0 ? 0 : value;
  }

  factory Printer.fromMap(Map<String, Object?> map) {
    return Printer(
      id: map['id']! as int,
      name: map['name']! as String,
      manufacturer: map['manufacturer']! as String,
      model: map['model']! as String,
      serialNumber: map['serial_number']! as String,
      nozzleSize: (map['nozzle_size']! as num).toDouble(),
      purchasePrice: (map['purchase_price']! as num).toDouble(),
      printedHours: (map['printed_hours']! as num).toDouble(),
      maintenanceInterval: (map['maintenance_interval']! as num).toDouble(),
      lastMaintenanceHours: (map['last_maintenance_hours']! as num).toDouble(),
      active: (map['active']! as int) == 1,
      notes: map['notes']! as String,
    );
  }
}
