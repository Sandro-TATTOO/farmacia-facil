class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String? alternativeAddress;
  final String? alternativePhone;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    this.alternativeAddress,
    this.alternativePhone,
    required this.createdAt,
  });

  // Converte para Map (para salvar no banco)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'alternativeAddress': alternativeAddress,
      'alternativePhone': alternativePhone,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Cria a partir de um Map (para ler do banco)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      alternativeAddress: map['alternativeAddress'],
      alternativePhone: map['alternativePhone'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  // Cria uma cópia com campos alterados
  UserModel copyWith({
    String? name,
    String? phone,
    String? address,
    String? alternativeAddress,
    String? alternativePhone,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      alternativeAddress: alternativeAddress ?? this.alternativeAddress,
      alternativePhone: alternativePhone ?? this.alternativePhone,
      createdAt: createdAt,
    );
  }
}
