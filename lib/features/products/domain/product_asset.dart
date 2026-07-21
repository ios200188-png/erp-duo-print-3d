class ProductImage {
  const ProductImage({
    required this.id,
    required this.productId,
    required this.filePath,
    required this.caption,
    required this.isPrimary,
    required this.createdAt,
  });

  final int id;
  final int productId;
  final String filePath;
  final String caption;
  final bool isPrimary;
  final DateTime createdAt;

  factory ProductImage.fromMap(Map<String, Object?> map) => ProductImage(
    id: map['id']! as int,
    productId: map['product_id']! as int,
    filePath: map['file_path']! as String,
    caption: (map['caption'] as String?) ?? '',
    isPrimary: (map['is_primary']! as int) == 1,
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']! as int),
  );
}

class ProductFile {
  const ProductFile({
    required this.id,
    required this.productId,
    required this.fileType,
    required this.fileName,
    required this.filePath,
    required this.version,
    required this.notes,
    required this.createdAt,
  });

  final int id;
  final int productId;
  final String fileType;
  final String fileName;
  final String filePath;
  final String version;
  final String notes;
  final DateTime createdAt;

  factory ProductFile.fromMap(Map<String, Object?> map) => ProductFile(
    id: map['id']! as int,
    productId: map['product_id']! as int,
    fileType: map['file_type']! as String,
    fileName: map['file_name']! as String,
    filePath: map['file_path']! as String,
    version: (map['version'] as String?) ?? '',
    notes: (map['notes'] as String?) ?? '',
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']! as int),
  );
}

class ProductVersion {
  const ProductVersion({
    required this.id,
    required this.productId,
    required this.version,
    required this.description,
    required this.weight,
    required this.printMinutes,
    required this.createdAt,
  });

  final int id;
  final int productId;
  final String version;
  final String description;
  final double weight;
  final int printMinutes;
  final DateTime createdAt;

  factory ProductVersion.fromMap(Map<String, Object?> map) => ProductVersion(
    id: map['id']! as int,
    productId: map['product_id']! as int,
    version: map['version']! as String,
    description: (map['description'] as String?) ?? '',
    weight: ((map['weight'] as num?) ?? 0).toDouble(),
    printMinutes: (map['print_minutes'] as int?) ?? 0,
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']! as int),
  );
}
