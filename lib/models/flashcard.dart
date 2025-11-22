import 'package:cloud_firestore/cloud_firestore.dart';

class Flashcard {
  final String id;
  final String english;    // Tên biến sử dụng trong app/UI
  final String vietnamese; // Tên biến sử dụng trong app/UI
  final String? note;       // SỬA: Đổi 'example' thành 'note' để khớp DB

  Flashcard({
    required this.id,
    required this.english,
    required this.vietnamese,
    this.note,
  });

  factory Flashcard.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return Flashcard(
      id: doc.id,
      english: data['front'] ?? '', 
      vietnamese: data['back'] ?? '',
      note: data['note'], 
    );
  }
}