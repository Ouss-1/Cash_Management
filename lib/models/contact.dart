class ContactModel {
  final String id;
  final String name;
  final String phone;
  final int colorValue;
  final DateTime createdAt;

  ContactModel({
    required this.id,
    required this.name,
    this.phone = '',
    required this.colorValue,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'colorValue': colorValue,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ContactModel.fromMap(Map<String, dynamic> map) {
    return ContactModel(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String? ?? '',
      colorValue: map['colorValue'] as int,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  ContactModel copyWith({
    String? id,
    String? name,
    String? phone,
    int? colorValue,
    DateTime? createdAt,
  }) {
    return ContactModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
