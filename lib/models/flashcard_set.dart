import 'package:cloud_firestore/cloud_firestore.dart';

// SỬA: ĐÃ XÓA CÁC DÒNG IMPORT LỖI (import home_screen, login_screen)

class FlashcardSet {
  final String id;
  final String title;
  final String description;
  final String color;
  final int cardCount;
  final String folder_id;

  FlashcardSet({
    required this.id,
    required this.title,
    required this.description,
    required this.color,
    required this.cardCount,
    required this.folder_id,
  });

  factory FlashcardSet.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return FlashcardSet(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      color: data['color'] ?? '#808080',
      cardCount: data['cardCount'] ?? 0,
      folder_id: data['folder_id'] ?? 'root',
    );
  }
}