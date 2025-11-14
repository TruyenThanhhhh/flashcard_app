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
    'en': english, // Key 'en'
    'vi': vietnamese, // Key 'vi'
    'example': example,
  };

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      id: json['id'],
      english: json['en'], // Đọc key 'en'
      vietnamese: json['vi'], // Đọc key 'vi'
      example: json['example'],
    );
  }
  
  // --- HÀM MỚI (QUAN TRỌNG) ---
  // Dùng để đọc dữ liệu từ Cloud Firestore
  // Service của chúng ta lưu key là 'english' và 'vietnamese'
  factory Flashcard.fromMap(String id, Map<String, dynamic> data) {
    return Flashcard(
      id: id, // ID lấy từ bên ngoài (doc.id)
      english: data['english'] ?? '', 
      vietnamese: data['vietnamese'] ?? '', 
      example: data['example'], 
    );
  }
}