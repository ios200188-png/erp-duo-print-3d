class BusinessSettings {
  const BusinessSettings({
    required this.companyName,
    required this.whatsapp,
    required this.document,
    required this.email,
    required this.address,
    required this.city,
    required this.kwhPrice,
    required this.printerPowerW,
    required this.laborHour,
    required this.machineHour,
    required this.packagingCost,
    required this.maintenancePercent,
    required this.failurePercent,
    required this.idealMarginPercent,
  });

  final String companyName;
  final String whatsapp;
  final String document;
  final String email;
  final String address;
  final String city;
  final double kwhPrice;
  final double printerPowerW;
  final double laborHour;
  final double machineHour;
  final double packagingCost;
  final double maintenancePercent;
  final double failurePercent;
  final double idealMarginPercent;

  factory BusinessSettings.fromMap(Map<String, Object?> map) {
    return BusinessSettings(
      companyName: map['company_name']! as String,
      whatsapp: map['whatsapp']! as String,
      document: (map['document'] as String?) ?? '',
      email: (map['email'] as String?) ?? '',
      address: (map['address'] as String?) ?? '',
      city: (map['city'] as String?) ?? '',
      kwhPrice: (map['kwh_price']! as num).toDouble(),
      printerPowerW: (map['printer_power_w']! as num).toDouble(),
      laborHour: (map['labor_hour']! as num).toDouble(),
      machineHour: (map['machine_hour']! as num).toDouble(),
      packagingCost: (map['packaging_cost']! as num).toDouble(),
      maintenancePercent: ((map['maintenance_percent'] as num?) ?? 3)
          .toDouble(),
      failurePercent: (map['failure_percent']! as num).toDouble(),
      idealMarginPercent: (map['ideal_margin_percent']! as num).toDouble(),
    );
  }
}
