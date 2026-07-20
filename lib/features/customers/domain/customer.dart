class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.document,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String name;
  final String phone;
  final String email;
  final String document;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Customer.fromMap(Map<String, Object?> map) {
    return Customer(
      id: map['id']! as int,
      name: map['name']! as String,
      phone: map['phone']! as String,
      email: map['email']! as String,
      document: map['document']! as String,
      notes: map['notes']! as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']! as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']! as int),
    );
  }
}
