import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category.dart';
import '../models/flashcard.dart';
import 'auth_service.dart'; // Để lấy user ID

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _auth = AuthService();

  String? get _uid => _auth.currentUser?.uid;

  // Lấy TẤT CẢ chủ đề dưới dạng Stream (tự động cập nhật)
  Stream<List<Category>> getCategories() {
    if (_uid == null) return Stream.value([]);
    
    var ref = _db.collection('users').doc(_uid).collection('categories');
    return ref.snapshots().asyncMap((snapshot) async {
      final categories = <Category>[];
      for (var doc in snapshot.docs) {
        final category = Category.fromMap(doc.id, doc.data());
        // Lấy các flashcard cho mỗi chủ đề
        final cards = await getFlashcardsForCategory(category.id);
        categories.add(category.copyWith(cards: cards));
      }
      return categories;
    });
  }

  // Lấy các flashcard cho 1 chủ đề cụ thể
  Future<List<Flashcard>> getFlashcardsForCategory(String categoryId) async {
    if (_uid == null) return [];
    
    var ref = _db.collection('users').doc(_uid)
                 .collection('categories').doc(categoryId)
                 .collection('flashcards');
                 
    var snapshot = await ref.get();
    return snapshot.docs
        .map((doc) => Flashcard.fromMap(doc.id, doc.data()))
        .toList();
  }

  // Thêm một chủ đề mới
  Future<void> addCategory(String name) async {
    if (_uid == null) return;
    
    var ref = _db.collection('users').doc(_uid).collection('categories');
    await ref.add({'name': name, 'createdAt': Timestamp.now()});
  }

  // Sửa tên chủ đề
  Future<void> updateCategoryName(String categoryId, String newName) async {
    if (_uid == null) return;
    
    var ref = _db.collection('users').doc(_uid).collection('categories').doc(categoryId);
    await ref.update({'name': newName});
  }

  // Xóa chủ đề (và tất cả flashcard bên trong)
  Future<void> deleteCategory(String categoryId) async {
    if (_uid == null) return;
    
    final categoryRef = _db.collection('users').doc(_uid).collection('categories').doc(categoryId);

    // 1. Xóa các flashcard bên trong
    final flashcards = await categoryRef.collection('flashcards').get();
    for (var doc in flashcards.docs) {
      await doc.reference.delete();
    }
    
    // 2. Xóa chủ đề
    await categoryRef.delete();
  }

  // --- Flashcard ---

  Future<void> addFlashcard(String categoryId, String english, String vietnamese) async {
    if (_uid == null) return;
    
    var ref = _db.collection('users').doc(_uid)
                 .collection('categories').doc(categoryId)
                 .collection('flashcards');
                 
    await ref.add({
      'english': english,
      'vietnamese': vietnamese,
      'createdAt': Timestamp.now(),
    });
  }

  Future<void> updateFlashcard(String categoryId, String cardId, String english, String vietnamese) async {
    if (_uid == null) return;
    
    var ref = _db.collection('users').doc(_uid)
                 .collection('categories').doc(categoryId)
                 .collection('flashcards').doc(cardId);
                 
    await ref.update({
      'english': english,
      'vietnamese': vietnamese,
    });
  }

  Future<void> deleteFlashcard(String categoryId, String cardId) async {
    if (_uid == null) return;
    
    var ref = _db.collection('users').doc(_uid)
                 .collection('categories').doc(categoryId)
                 .collection('flashcards').doc(cardId);
                 
    await ref.delete();
  }

  // --- Learning Session (Buổi học) ---

  Future<void> recordLearningSession({
    required String categoryId,
    required String categoryName,
    required Duration duration,
    required int cardsLearned,
  }) async {
    if (_uid == null) return;
    
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
    if (_uid == null) return;
    
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

  // Lấy các buổi học gần đây
  Future<List<QueryDocumentSnapshot>> getRecentSessions(int limit) async {
    if (_uid == null) return [];
    
    var ref = _db.collection('users').doc(_uid).collection('sessions')
                 .orderBy('timestamp', descending: true)
                 .limit(limit);
                 
    var snapshot = await ref.get();
    return snapshot.docs;
  }
}