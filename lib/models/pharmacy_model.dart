class PharmacyModel {
  final String id;
  final String name;
  final String address;
  final String phone;
  final double latitude;
  final double longitude;
  final double distanceKm;    // Distância do usuário em km
  final bool hasDelivery;
  final bool hasPickup;
  final String openingHours;  // Ex: "Seg-Sex: 8h-20h"
  final bool isOpen;
  final double rating;        // Avaliação 0-5

  PharmacyModel({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
    required this.hasDelivery,
    required this.hasPickup,
    required this.openingHours,
    required this.isOpen,
    required this.rating,
  });

  // Formata a distância para exibição
  String get formattedDistance {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).toStringAsFixed(0)}m';
    }
    return '${distanceKm.toStringAsFixed(1)}km';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'latitude': latitude,
      'longitude': longitude,
      'distanceKm': distanceKm,
      'hasDelivery': hasDelivery,
      'hasPickup': hasPickup,
      'openingHours': openingHours,
      'isOpen': isOpen,
      'rating': rating,
    };
  }

  factory PharmacyModel.fromMap(Map<String, dynamic> map) {
    return PharmacyModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      phone: map['phone'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      distanceKm: (map['distanceKm'] ?? 0.0).toDouble(),
      hasDelivery: map['hasDelivery'] ?? false,
      hasPickup: map['hasPickup'] ?? true,
      openingHours: map['openingHours'] ?? '',
      isOpen: map['isOpen'] ?? false,
      rating: (map['rating'] ?? 0.0).toDouble(),
    );
  }
}
