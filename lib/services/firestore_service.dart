// lib/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// SỬA: Dùng model mới
import '../models/flashcard_set.dart'; 
import '../models/flashcard.dart';
import 'auth_service.dart'; // Giữ nguyên

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  // SỬA: Lấy auth instance trực tiếp
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // final AuthService _auth = AuthService(); // Không cần thiết

  String? get _uid => _auth.currentUser?.uid;

  // === PHẦN USER ===

  // MỚI: Lấy stream của user document (dùng cho home_screen)
  Stream<DocumentSnapshot> getUserStream() {
    if (_uid == null) {
      // Trả về stream rỗng nếu chưa đăng nhập
      return Stream.error(Exception("Chưa đăng nhập")); 
    }
    return _db.collection('users').doc(_uid).snapshots();
  }


  // === PHẦN FLASHCARD SETS (Category cũ) ===

  // SỬA: Đổi tên hàm và sửa lỗi N+1
  // Hàm này CHỈ lấy các bộ thẻ (metadata), KHÔNG lấy card
  Stream<List<FlashcardSet>> getFlashcardSetsStream() {
    if (_uid == null) return Stream.value([]);
    
    return _db
        .collection('users')
        .doc(_uid)
        .collection('flashcard_sets') // SỬA: Đường dẫn DB
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FlashcardSet.fromFirestore(doc)) // SỬA: Dùng model
            .toList());
  }

  // SỬA: Tên hàm và logic
  Future<void> addFlashcardSet(String title) async {
    if (_uid == null) throw Exception("Chưa đăng nhập");
    
    // SỬA: Đường dẫn DB
    await _db.collection('users').doc(_uid).collection('flashcard_sets').add({
      'title': title, // SỬA: Tên trường
      'description': '',
      'color': '#4CAF50', // Màu xanh mặc định
      'cardCount': 0, // Mặc định là 0
      'folder_id': 'root',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // SỬA: Tên hàm và logic
  Future<void> updateFlashcardSetTitle(String setId, String newTitle) async {
    if (_uid == null) throw Exception("Chưa đăng nhập");

    await _db
        .collection('users')
        .doc(_uid)
        .collection('flashcard_sets') // SỬA: Đường dẫn DB
        .doc(setId)
        .update({'title': newTitle}); // SỬA: Tên trường
  }

  // SỬA: Tên hàm và logic
  Future<void> deleteFlashcardSet(String setId) async {
    if (_uid == null) throw Exception("Chưa đăng nhập");
    
    final setRef = _db
        .collection('users')
        .doc(_uid)
        .collection('flashcard_sets') // SỬA: Đường dẫn DB
        .doc(setId);

    // LƯU Ý: Xóa subcollection từ client RẤT NGUY HIỂM.
    // Cách tốt nhất là dùng Cloud Function.
    // Tạm thời, chúng ta chỉ xóa document bộ thẻ.
    // Các thẻ con sẽ bị "mồ côi" (orphaned) trong DB.
    await setRef.delete();
    
    // TODO: Triển khai Cloud Function để xóa các 'cards' bên trong
  }


  // === PHẦN FLASHCARDS (Cards) ===

  // SỬA: Đổi tên hàm và trả về STREAM (cho flashcard_screen)
  Stream<List<Flashcard>> getFlashcardsStream(String setId) {
    if (_uid == null) return Stream.value([]);

    return _db
        .collection('users')
        .doc(_uid)
        .collection('flashcard_sets') // SỬA: Đường dẫn
        .doc(setId)
        .collection('cards') // SỬA: Đường dẫn
        .orderBy('created_at')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Flashcard.fromFirestore(doc)) // SỬA: Dùng model
            .toList());
  }

  // SỬA: Cập nhật logic để khớp DB
  Future<void> addFlashcard(String setId, String front, String back) async {
    if (_uid == null) throw Exception("Chưa đăng nhập");

    final cardCollection = _db
        .collection('users')
        .doc(_uid)
        .collection('flashcard_sets') // SỬA
        .doc(setId)
        .collection('cards'); // SỬA
    
    // 1. Thêm thẻ mới
    await cardCollection.add({
      'front': front, // SỬA: Tên trường
      'back': back,   // SỬA: Tên trường
      'created_at': FieldValue.serverTimestamp(),
      'note': '',
    });

    // 2. CẬP NHẬT cardCount (Rất quan trọng)
    final setRef = _db
        .collection('users')
        .doc(_uid)
        .collection('flashcard_sets')
        .doc(setId);
    await setRef.update({'cardCount': FieldValue.increment(1)});
  }

  Future<List<Flashcard>> getFlashcardsOnce(String setId) async {
    if (_uid == null) return [];

    final snapshot = await _db
        .collection('users')
        .doc(_uid)
        .collection('flashcard_sets')
        .doc(setId)
        .collection('cards')
        .orderBy('created_at')
        .get(); // <--- Dùng .get()
        
    return snapshot.docs
        .map((doc) => Flashcard.fromFirestore(doc))
        .toList();
  }

  // SỬA: Cập nhật logic để khớp DB
  Future<void> updateFlashcard(
      String setId, String cardId, String front, String back) async {
    if (_uid == null) throw Exception("Chưa đăng nhập");

    await _db
        .collection('users')
        .doc(_uid)
        .collection('flashcard_sets') // SỬA
        .doc(setId)
        .collection('cards') // SỬA
        .doc(cardId)
        .update({
      'front': front, // SỬA
      'back': back,   // SỬA
    });
  }

  // SỬA: Cập nhật logic để khớp DB
  Future<void> deleteFlashcard(String setId, String cardId) async {
    if (_uid == null) throw Exception("Chưa đăng nhập");
    
    // 1. Xóa thẻ
    await _db
        .collection('users')
        .doc(_uid)
        .collection('flashcard_sets') // SỬA
        .doc(setId)
        .collection('cards') // SỬA
        .doc(cardId)
        .delete();
    
    // 2. CẬP NHẬT cardCount (Rất quan trọng)
    final setRef = _db
        .collection('users')
        .doc(_uid)
        .collection('flashcard_sets')
        .doc(setId);
    await setRef.update({'cardCount': FieldValue.increment(-1)});
  }

  // --- Learning Session (Buổi học) ---
  // (Giữ nguyên logic này vì có vẻ nó đúng)

  Future<void> recordLearningSession({
    required String categoryId,
    required String categoryName,
    required Duration duration,
    required int cardsLearned,
  }) async {
    if (_uid == null) throw Exception("Chưa đăng nhập");
    
    var ref = _db.collection('users').doc(_uid).collection('sessions');
    await ref.add({
      'type': 'learning',
      'categoryId': categoryId,
      'categoryName': categoryName,
      'duration': duration.inSeconds, // Lưu bằng giây
      'cardsLearned': cardsLearned,
      'timestamp': Timestamp.now(),
    });
  }

  Future<void> recordQuizSession({
    required String categoryId,
    required String categoryName,
    required Duration duration,
    required int quizScore,
    required int totalQuestions,
  }) async {
    if (_uid == null) throw Exception("Chưa đăng nhập");
    
    var ref = _db.collection('users').doc(_uid).collection('sessions');
    await ref.add({
      'type': 'quiz',
      'categoryId': categoryId,
      'categoryName': categoryName,
      'duration': duration.inSeconds,
      'quizScore': quizScore,
      'totalQuestions': totalQuestions,
      'timestamp': Timestamp.now(),
    });
  }

  // --- Statistics (Thống kê) ---

  Future<List<QueryDocumentSnapshot>> getRecentSessions(int limit) async {
    if (_uid == null) throw Exception("Chưa đăng nhập");
    
    var ref = _db.collection('users').doc(_uid).collection('sessions')
        .orderBy('timestamp', descending: true)
        .limit(limit);
            
    var snapshot = await ref.get();
    return snapshot.docs;
  }
}