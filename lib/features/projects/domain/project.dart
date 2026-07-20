class Project {
  const Project({
    required this.id,
    required this.name,
    required this.version,
    required this.defaultMaterial,
    required this.estimatedWeight,
    required this.printMinutes,
    required this.infillPercent,
    required this.layerHeight,
    required this.nozzleSize,
    required this.suggestedPrice,
    required this.filePath,
    required this.notes,
    required this.active,
  });

  final int id;
  final String name;
  final String version;
  final String defaultMaterial;
  final double estimatedWeight;
  final int printMinutes;
  final double infillPercent;
  final double layerHeight;
  final double nozzleSize;
  final double suggestedPrice;
  final String filePath;
  final String notes;
  final bool active;

  String get formattedTime {
    final hours = printMinutes ~/ 60;
    final minutes = printMinutes % 60;
    return '${hours}h ${minutes.toString().padLeft(2, '0')}min';
  }

  factory Project.fromMap(Map<String, Object?> map) {
    return Project(
      id: map['id']! as int,
      name: map['name']! as String,
      version: map['version']! as String,
      defaultMaterial: map['default_material']! as String,
      estimatedWeight: (map['estimated_weight']! as num).toDouble(),
      printMinutes: map['print_minutes']! as int,
      infillPercent: (map['infill_percent']! as num).toDouble(),
      layerHeight: (map['layer_height']! as num).toDouble(),
      nozzleSize: (map['nozzle_size']! as num).toDouble(),
      suggestedPrice: (map['suggested_price']! as num).toDouble(),
      filePath: map['file_path']! as String,
      notes: map['notes']! as String,
      active: (map['active']! as int) == 1,
    );
  }
}
