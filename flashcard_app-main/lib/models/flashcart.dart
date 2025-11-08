class Flashcard {
  final String id;
  final String english;
  final String vietnamese;
  final String? example;

  Flashcard({
    required this.id,
    required this.english,
    required this.vietnamese,
    this.example,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'en': english,
    'vi': vietnamese,
    'example': example,
  };

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      id: json['id'],
      english: json['en'],
      vietnamese: json['vi'],
      example: json['example'],
    );
  }
}
