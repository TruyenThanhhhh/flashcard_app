import 'package:cloud_firestore/cloud_firestore.dart';

// ĐÂY LÀ NỘI DUNG ĐÚNG CỦA FILE NÀY
// (Nó định nghĩa "FlashcardSet" là gì)

class FlashcardSet {
  final String id;
  final String title;
  final String description;
  final String color;
  final int cardCount;
  final String folder_id;
  final bool isPublic;
  final String? userId; // For public lessons, to identify the creator
  final String? creatorName; // For public lessons, to show creator name

  FlashcardSet({
    required this.id,
    required this.title,
    required this.description,
    required this.color,
    required this.cardCount,
    required this.folder_id,
    this.isPublic = false,
    this.userId,
    this.creatorName,
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
      isPublic: data['isPublic'] ?? false,
      userId: data['userId'],
      creatorName: data['creatorName'],
    );
  }
}