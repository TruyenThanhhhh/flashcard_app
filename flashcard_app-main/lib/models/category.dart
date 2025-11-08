import 'flashcart.dart';

class Category {
  final String id;
  final String name;
  final List<Flashcard> cards;

  Category({required this.id, required this.name, required this.cards});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      cards: (json['cards'] as List<dynamic>?)?.map((e) => Flashcard.fromJson(e)).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'cards': cards.map((c) => c.toJson()).toList(),
    };
  }
}

class QuizResult {
  final String categoryId;
  final int total;
  final int correct;
  final DateTime createdAt;

  QuizResult({required this.categoryId, required this.total, required this.correct, required this.createdAt});

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      categoryId: json['categoryId'],
      total: json['total'],
      correct: json['correct'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'total': total,
      'correct': correct,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
