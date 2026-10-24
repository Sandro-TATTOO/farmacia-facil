class MedicationModel {
  final String id;
  final String userId;
  final String name;
  final String dosage;        // Ex: "500mg"
  final String instructions;  // Ex: "Tomar com água"
  final int timesPerDay;      // Quantas vezes por dia
  final List<String> times;   // Horários: ["08:00", "20:00"]
  final DateTime startDate;
  final DateTime endDate;
  final int totalDays;
  final int totalPills;       // Total de comprimidos
  final int remainingPills;   // Comprimidos restantes
  final bool isActive;
  final DateTime createdAt;

  MedicationModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.dosage,
    required this.instructions,
    required this.timesPerDay,
    required this.times,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.totalPills,
    required this.remainingPills,
    required this.isActive,
    required this.createdAt,
  });

  // Calcula o percentual restante
  double get remainingPercentage =>
      totalPills > 0 ? (remainingPills / totalPills) * 100 : 0;

  // Verifica se está acabando (menos de 20% restante)
  bool get isRunningLow => remainingPercentage < 20;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'dosage': dosage,
      'instructions': instructions,
      'timesPerDay': timesPerDay,
      'times': times,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'totalDays': totalDays,
      'totalPills': totalPills,
      'remainingPills': remainingPills,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory MedicationModel.fromMap(Map<String, dynamic> map) {
    return MedicationModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      dosage: map['dosage'] ?? '',
      instructions: map['instructions'] ?? '',
      timesPerDay: map['timesPerDay'] ?? 1,
      times: List<String>.from(map['times'] ?? []),
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      totalDays: map['totalDays'] ?? 0,
      totalPills: map['totalPills'] ?? 0,
      remainingPills: map['remainingPills'] ?? 0,
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  MedicationModel copyWith({
    int? remainingPills,
    bool? isActive,
  }) {
    return MedicationModel(
      id: id,
      userId: userId,
      name: name,
      dosage: dosage,
      instructions: instructions,
      timesPerDay: timesPerDay,
      times: times,
      startDate: startDate,
      endDate: endDate,
      totalDays: totalDays,
      totalPills: totalPills,
      remainingPills: remainingPills ?? this.remainingPills,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}
