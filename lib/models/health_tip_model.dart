class HealthTipModel {
  final String id;
  final String title;
  final String content;
  final String category;  // Ex: "Medicamentos", "Alimentação", "Exercícios"
  final String imageUrl;
  final DateTime publishedAt;

  HealthTipModel({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.imageUrl,
    required this.publishedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category,
      'imageUrl': imageUrl,
      'publishedAt': publishedAt.toIso8601String(),
    };
  }

  factory HealthTipModel.fromMap(Map<String, dynamic> map) {
    return HealthTipModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      category: map['category'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      publishedAt: DateTime.parse(map['publishedAt']),
    );
  }
}
