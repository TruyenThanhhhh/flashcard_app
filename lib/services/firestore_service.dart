import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/flashcard_set.dart';
import '../models/flashcard.dart';
import '../models/note.dart'; // MỚI: Import model Note

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // === USER ===
  Stream<DocumentSnapshot> getUserStream() {
    if (_uid == null) {
      return Stream.error(Exception("Chưa đăng nhập")); 
    }
    return _db.collection('users').doc(_uid).snapshots();
  }

  // === FLASHCARD SETS ===
  Stream<List<FlashcardSet>> getFlashcardSetsStream() {
    if (_uid == null) return Stream.value([]);
    
    return _db
        .collection('users')
        .doc(_uid)
        .collection('flashcard_sets') 
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FlashcardSet.fromFirestore(doc))
            .toList());
  }

  Future<void> addFlashcardSet(String title) async {
    if (_uid == null) throw Exception("Chưa đăng nhập");
    
    await _db.collection('users').doc(_uid).collection('flashcard_sets').add({
      'title': title,
      'description': '',
      'color': '#4CAF50',
      'cardCount': 0,
      'folder_id': 'root',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateFlashcardSetTitle(String setId, String newTitle) async {
    if (_uid == null) throw Exception("Chưa đăng nhập");

    await _db
        .collection('users')
        .doc(_uid)
        .collection('flashcard_sets')
        .doc(setId)
        .update({'title': newTitle});
  }

  Future<void> deleteFlashcardSet(String setId) async {
    if (_uid == null) throw Exception("Chưa đăng nhập");
    
    final setRef = _db
        .collection('users')
        .doc(_uid)
        .collection('flashcard_sets')
        .doc(setId);
    
    // Lưu ý: Subcollection 'cards' vẫn còn trong DB (orphan)
    // Cần Cloud Function để xóa triệt để.
    await setRef.delete();
  }

  // === FLASHCARDS (Cards) ===
  Stream<List<Flashcard>> getFlashcardsStream(String setId) {
    if (_uid == null) return Stream.value([]);

    return _db
        .collection('users')
        .doc(_uid)
        .collection('flashcard_sets')
        .doc(setId)
        .collection('cards')
        .orderBy('created_at')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Flashcard.fromFirestore(doc))
            .toList());
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
        .get();
        
    return snapshot.docs
        .map((doc) => Flashcard.fromFirestore(doc))
        .toList();
  }

  Future<void> addFlashcard(String setId, String front, String back) async {
    if (_uid == null) throw Exception("Chưa đăng nhập");

    final cardCollection = _db
        .collection('users')
        .doc(_uid)
        .collection('flashcard_sets')
        .doc(setId)
        .collection('cards');
    
    await cardCollection.add({
      'front': front,
      'back': back,
      'created_at': FieldValue.serverTimestamp(),
      'note': '',
    });

    final setRef = _db
        .collection('users')
        .doc(_uid)
        .collection('flashcard_sets')
        .doc(setId);
    await setRef.update({'cardCount': FieldValue.increment(1)});
  }

  Future<void> updateFlashcard(
      String setId, String cardId, String front, String back) async {
    if (_uid == null) throw Exception("Chưa đăng nhập");

    await _db
        .collection('users')
        .doc(_uid)
        .collection('flashcard_sets')
        .doc(setId)
        .collection('cards')
        .doc(cardId)
        .update({
      'front': front,
      'back': back,
    });
  }

  Future<void> deleteFlashcard(String setId, String cardId) async {
    if (_uid == null) throw Exception("Chưa đăng nhập");
    
    await _db
        .collection('users')
        .doc(_uid)
        .collection('flashcard_sets')
        .doc(setId)
        .collection('cards')
        .doc(cardId)
        .delete();
    
    final setRef = _db
        .collection('users')
        .doc(_uid)
        .collection('flashcard_sets')
        .doc(setId);
    await setRef.update({'cardCount': FieldValue.increment(-1)});
  }

  // === SESSIONS ===
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
      'duration': duration.inSeconds,
      'cardsLearned': cardsLearned,
      'timestamp': Timestamp.now(),
    });
    
    // Cập nhật tổng giờ học
    final userRef = _db.collection('users').doc(_uid);
    await userRef.update({
      'stats.totalHours': FieldValue.increment(duration.inHours > 0 ? duration.inHours : (duration.inMinutes / 60)),
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

  // === STATISTICS ===
  Future<List<QueryDocumentSnapshot>> getRecentSessions(int limit) async {
    if (_uid == null) throw Exception("Chưa đăng nhập");
    
    var ref = _db.collection('users').doc(_uid).collection('sessions')
        .orderBy('timestamp', descending: true)
        .limit(limit);
            
    var snapshot = await ref.get();
    return snapshot.docs;
  }

  // ==================================================
  // === MỚI: PHẦN XỬ LÝ GHI CHÚ (NOTES) ===
  // ==================================================

  Stream<List<Note>> getNotesStream() {
    if (_uid == null) return Stream.value([]);

    return _db
        .collection('users')
        .doc(_uid)
        .collection('notes')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Note.fromFirestore(doc))
            .toList());
  }

  Future<void> addNote(String title, String content) async {
    if (_uid == null) throw Exception("Chưa đăng nhập");

    await _db.collection('users').doc(_uid).collection('notes').add({
      'title': title,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Cập nhật thống kê số lượng ghi chú
    final userRef = _db.collection('users').doc(_uid);
    await userRef.update({'stats.totalNotes': FieldValue.increment(1)});
  }

  Future<void> updateNote(String noteId, String title, String content) async {
    if (_uid == null) throw Exception("Chưa đăng nhập");

    await _db
        .collection('users')
        .doc(_uid)
        .collection('notes')
        .doc(noteId)
        .update({
      'title': title,
      'content': content,
      // 'updatedAt': FieldValue.serverTimestamp(), // Có thể thêm nếu muốn
    });
  }

  Future<void> deleteNote(String noteId) async {
    if (_uid == null) throw Exception("Chưa đăng nhập");

    await _db
        .collection('users')
        .doc(_uid)
        .collection('notes')
        .doc(noteId)
        .delete();

    // Giảm thống kê số lượng ghi chú
    final userRef = _db.collection('users').doc(_uid);
    await userRef.update({'stats.totalNotes': FieldValue.increment(-1)});
  }
}