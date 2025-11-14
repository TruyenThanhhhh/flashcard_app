// lib/models/flashcard.dart
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

  // SỬA: Hợp nhất các hàm fromJson/fromMap thành một
  // factory constructor duy nhất để đọc từ Firestore.
  // Đây là hàm mà firestore_service sẽ gọi.
  factory Flashcard.fromFirestore(DocumentSnapshot doc) {
    // Lấy dữ liệu Map từ Firestore
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return Flashcard(
      id: doc.id,
      // QUAN TRỌNG: Ánh xạ key 'front' từ DB -> 'english' trong app
      english: data['front'] ?? '', 
      // QUAN TRỌNG: Ánh xạ key 'back' từ DB -> 'vietnamese' trong app
      vietnamese: data['back'] ?? '',
      // QUAN TRỌNG: Ánh xạ key 'note' từ DB -> 'note' trong app
      note: data['note'], 
    );
  }
}