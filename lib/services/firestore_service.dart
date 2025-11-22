import 'dart:math'; // Để random ID
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/flashcard_set.dart';
import '../models/flashcard.dart';
import '../models/note.dart';
import '../models/app_notification.dart';
import '../models/study_reminder.dart'; // Import model StudyReminder
import '../services/notification_service.dart'; // Import NotificationService

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // ==================================================
  // === USER DATA ===
  // ==================================================

  Stream<DocumentSnapshot> getUserStream() {
    if (_uid == null) {
      return Stream.error(Exception("Chưa đăng nhập"));
    }
    return _db.collection('users').doc(_uid).snapshots();
  }

  // ==================================================
  // === FLASHCARD SETS (BỘ THẺ) ===
  // ==================================================

  Future<int> getFlashcardSetsCount() async {
    if (_uid == null) return 0;
    
    final aggregateQuery = await _db
        .collection('users')
        .doc(_uid)
        .collection('flashcard_sets')
        .count()
        .get();
        
    return aggregateQuery.count ?? 0;
  }

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

  // Lấy danh sách bài học công khai từ tất cả người dùng
  Stream<List<FlashcardSet>> getPublicLessonsStream({String? searchQuery}) {
    Query query = _db.collection('public_lessons')
        .where('cardCount', isGreaterThan: 0) // Chỉ hiện bài có thẻ
        .orderBy('cardCount', descending: true);
    
    return query.snapshots().map((snapshot) {
      var lessons = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // Tạo FlashcardSet từ dữ liệu public lesson
        return FlashcardSet(
          id: data['lessonId'] ?? doc.id,
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          color: data['color'] ?? '#4CAF50',
          cardCount: data['cardCount'] ?? 0,
          folder_id: 'root',
          // Các trường bổ sung cho public
          // isPublic: true,
          // userId: data['userId'],
          // creatorName: data['creatorName'],
        );
      }).toList();
      
      // Lọc theo từ khóa tìm kiếm (nếu có) - Client side filtering
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lowerQuery = searchQuery.toLowerCase();
        lessons = lessons.where((lesson) => 
          lesson.title.toLowerCase().contains(lowerQuery)
        ).toList();
      }
      
      return lessons;
    });
  }

  // Thêm bộ thẻ mới (Hợp nhất logic cũ và mới)
  Future<void> addFlashcardSet(String title, {bool isPublic = false}) async {
    if (_uid == null) throw Exception("Chưa đăng nhập");
    
    // Lưu vào collection riêng của user
    DocumentReference docRef = await _db.collection('users').doc(_uid).collection('flashcard_sets').add({
      'title': title,
      'description': '',
      'color': '#4CAF50',
      'cardCount': 0,
      'folder_id': 'root',
      'isPublic': isPublic,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Nếu là public, thêm vào collection chung (public_lessons)
    if (isPublic) {
      final userDoc = await _db.collection('users').doc(_uid).get();
      final userData = userDoc.data();
      final creatorName = userData?['name'] ?? 'Người dùng';

      await _db.collection('public_lessons').add({
        'lessonId': docRef.id,
        'userId': _uid,
        'creatorName': creatorName,
        'title': title,
        'description': '',
        'color': '#4CAF50',
        'cardCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await addNotification(
      title: 'Chủ đề mới',
      body: 'Bạn vừa tạo chủ đề "$title". Hãy thêm thẻ để bắt đầu học nhé!',
      type: 'system',
    );
  }

  Future<void> updateFlashcardSetTitle(String setId, String newTitle) async {
    if (_uid == null) throw Exception("Chưa đăng nhập");

    // Cập nhật trong flashcard_sets
    await _db
        .collection('users')
        .doc(_uid)
        .collection('flashcard_sets')
        .doc(setId)
        .update({'title': newTitle});
    
    // Kiểm tra nếu là public lesson thì cập nhật cả bên public_lessons
    final setDoc = await _db.collection('users').doc(_uid).collection('flashcard_sets').doc(setId).get();
    final setData = setDoc.data();
    if (setData != null && setData['isPublic'] == true) {
      final publicLessonsQuery = await _db.collection('public_lessons')
          .where('lessonId', isEqualTo: setId)
          .where('userId', isEqualTo: _uid)
          .get();
      
      if (publicLessonsQuery.docs.isNotEmpty) {
        await publicLessonsQuery.docs.first.reference.update({'title': newTitle});
      }
    }
  }

  // Cập nhật quyền riêng tư của bộ thẻ
  Future<void> updateFlashcardSetPrivacy(String setId, bool isPublic) async {
    if (_uid == null) throw Exception("Chưa đăng nhập");

    final setRef = _db.collection('users').doc(_uid).collection('flashcard_sets').doc(setId);
    final setDoc = await setRef.get();
    final setData = setDoc.data();
    
    if (setData == null) throw Exception("Không tìm thấy chủ đề");
    
    final currentIsPublic = setData['isPublic'] ?? false;
    final cardCount = setData['cardCount'] ?? 0;
    
    // Cập nhật trạng thái trong flashcard_sets
    await setRef.update({'isPublic': isPublic});
    
    if (isPublic && !currentIsPublic) {
      // Chuyển thành Public -> Thêm vào public_lessons
      final userDoc = await _db.collection('users').doc(_uid).get();
      final userData = userDoc.data();
      final creatorName = userData?['name'] ?? 'Người dùng';
      
      // Kiểm tra xem đã tồn tại chưa để tránh trùng lặp
      final existingQuery = await _db.collection('public_lessons')
          .where('lessonId', isEqualTo: setId)
          .where('userId', isEqualTo: _uid)
          .get();
      
      if (existingQuery.docs.isEmpty) {
        await _db.collection('public_lessons').add({
          'lessonId': setId,
          'userId': _uid,
          'creatorName': creatorName,
          'title': setData['title'] ?? '',
          'description': setData['description'] ?? '',
          'color': setData['color'] ?? '#4CAF50',
          'cardCount': cardCount,
          'createdAt': setData['createdAt'] ?? FieldValue.serverTimestamp(),
        });
      } else {
        // Đã có thì update
        await existingQuery.docs.first.reference.update({
          'cardCount': cardCount,
          'title': setData['title'] ?? '',
        });
      }
    } else if (!isPublic && currentIsPublic) {
      // Chuyển thành Private -> Xóa khỏi public_lessons
      final publicLessonsQuery = await _db.collection('public_lessons')
          .where('lessonId', isEqualTo: setId)
          .where('userId', isEqualTo: _uid)
          .get();
      
      for (var doc in publicLessonsQuery.docs) {
        await doc.reference.delete();
      }
    }
  }

  Future<void> deleteFlashcardSet(String setId) async {
    if (_uid == null) throw Exception("Chưa đăng nhập");

    final setRef = _db
        .collection('users')
        .doc(_uid)
        .collection('flashcard_sets')
        .doc(setId);
    
    // Xóa bộ thẻ
    await setRef.delete();

    // Xóa luôn khỏi public_lessons nếu có
    final publicLessonsQuery = await _db.collection('public_lessons')
        .where('lessonId', isEqualTo: setId)
        .where('userId', isEqualTo: _uid)
        .get();
    
    for (var doc in publicLessonsQuery.docs) {
      await doc.reference.delete();
    }
  }

  // ==================================================
  // === FLASHCARDS (THẺ HỌC) ===
  // ==================================================

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

  // Lấy danh sách thẻ 1 lần (Hợp nhất: hỗ trợ cả userId khác cho Public Lesson)
  Future<List<Flashcard>> getFlashcardsOnce(String setId, {String? userId}) async {
    final targetUserId = userId ?? _uid;
    if (targetUserId == null) return [];

    final snapshot = await _db
        .collection('users')
        .doc(targetUserId)
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

    // Kiểm tra xem bộ thẻ có public không để cập nhật count bên ngoài
    final setRef = _db.collection('users').doc(_uid).collection('flashcard_sets').doc(setId);
    final setDoc = await setRef.get();
    final setData = setDoc.data();
    final isPublic = setData != null && setData['isPublic'] == true;

    // Thêm thẻ vào sub-collection 'cards'
    await setRef.collection('cards').add({
      'front': front,
      'back': back,
      'created_at': FieldValue.serverTimestamp(),
      'note': '',
    });

    // Tăng số lượng thẻ trong bộ (Chỉ gọi 1 lần)
    await setRef.update({'cardCount': FieldValue.increment(1)});
    
    // Nếu public, cập nhật count trong public_lessons
    if (isPublic) {
      final publicLessonsQuery = await _db.collection('public_lessons')
          .where('lessonId', isEqualTo: setId)
          .where('userId', isEqualTo: _uid)
          .get();
      
      if (publicLessonsQuery.docs.isNotEmpty) {
        await publicLessonsQuery.docs.first.reference.update({
          'cardCount': FieldValue.increment(1),
        });
      }
    }
    
    // Tăng tổng số thẻ trong stats user
    final userRef = _db.collection('users').doc(_uid);
    await userRef.update({'stats.totalFlashcards': FieldValue.increment(1)});
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

    final setRef = _db.collection('users').doc(_uid).collection('flashcard_sets').doc(setId);
    final setDoc = await setRef.get();
    final setData = setDoc.data();
    final isPublic = setData != null && setData['isPublic'] == true;

    // Xóa thẻ
    await setRef.collection('cards').doc(cardId).delete();

    // Giảm số lượng thẻ trong bộ (Chỉ gọi 1 lần)
    await setRef.update({'cardCount': FieldValue.increment(-1)});
    
    // Nếu public, cập nhật count trong public_lessons
    if (isPublic) {
      // Lấy lại cardCount chính xác sau khi giảm (hoặc dùng increment -1)
      // Dùng increment cho an toàn
      final publicLessonsQuery = await _db.collection('public_lessons')
          .where('lessonId', isEqualTo: setId)
          .where('userId', isEqualTo: _uid)
          .get();
      
      if (publicLessonsQuery.docs.isNotEmpty) {
        await publicLessonsQuery.docs.first.reference.update({
          'cardCount': FieldValue.increment(-1),
        });
      }
    }
    
    // Giảm tổng số thẻ trong stats user
    final userRef = _db.collection('users').doc(_uid);
    await userRef.update({'stats.totalFlashcards': FieldValue.increment(-1)});
  }

  // ==================================================
  // === NOTES (GHI CHÚ) ===
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

    final userRef = _db.collection('users').doc(_uid);
    await userRef.update({'stats.totalNotes': FieldValue.increment(-1)});
  }

  // ==================================================
  // === NOTIFICATIONS (THÔNG BÁO) ===
  // ==================================================

  Stream<List<AppNotification>> getNotificationsStream() {
    if (_uid == null) return Stream.value([]);

    return _db
        .collection('users')
        .doc(_uid)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppNotification.fromFirestore(doc))
            .toList());
  }

  Stream<int> getUnreadNotificationsCount() {
    if (_uid == null) return Stream.value(0);

    return _db
        .collection('users')
        .doc(_uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> addNotification({
    required String title,
    required String body,
    String type = 'system',
  }) async {
    if (_uid == null) return;

    await _db.collection('users').doc(_uid).collection('notifications').add({
      'title': title,
      'body': body,
      'isRead': false,
      'type': type,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    if (_uid == null) return;

    await _db
        .collection('users')
        .doc(_uid)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> markAllNotificationsAsRead() async {
    if (_uid == null) return;

    final batch = _db.batch();
    final snapshots = await _db
        .collection('users')
        .doc(_uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in snapshots.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  Future<void> deleteNotification(String notificationId) async {
    if (_uid == null) return;

    await _db
        .collection('users')
        .doc(_uid)
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }

  // ==================================================
  // === REMINDERS (NHẮC NHỞ) ===
  // ==================================================

  Stream<List<StudyReminder>> getRemindersStream() {
    if (_uid == null) return Stream.value([]);
    
    return _db.collection('users').doc(_uid).collection('reminders')
        .snapshots()
        .map((snap) {
          List<StudyReminder> reminders = snap.docs
              .map((doc) => StudyReminder.fromFirestore(doc))
              .toList();
          
          reminders.sort((a, b) {
            int cmp = a.hour.compareTo(b.hour);
            if (cmp != 0) return cmp;
            return a.minute.compareTo(b.minute);
          });

          return reminders;
        });
  }

  Future<void> addReminder(String title, int hour, int minute, List<int> weekDays) async {
    if (_uid == null) return;

    int notificationId = Random().nextInt(100000);

    DocumentReference docRef = await _db.collection('users').doc(_uid).collection('reminders').add({
      'title': title,
      'hour': hour,
      'minute': minute,
      'weekDays': weekDays,
      'isEnabled': true,
      'notificationId': notificationId,
    });

    StudyReminder newReminder = StudyReminder(
      id: docRef.id,
      title: title,
      hour: hour,
      minute: minute,
      weekDays: weekDays,
      isEnabled: true,
      notificationId: notificationId,
    );
    await NotificationService().scheduleReminder(newReminder);
  }

  Future<void> updateReminder(StudyReminder reminder) async {
    if (_uid == null) return;

    await _db.collection('users').doc(_uid).collection('reminders').doc(reminder.id).update(reminder.toMap());

    await NotificationService().scheduleReminder(reminder);
  }

  Future<void> toggleReminder(StudyReminder reminder, bool isEnabled) async {
    if (_uid == null) return;

    await _db.collection('users').doc(_uid).collection('reminders').doc(reminder.id).update({'isEnabled': isEnabled});

    StudyReminder updated = StudyReminder(
      id: reminder.id,
      title: reminder.title,
      hour: reminder.hour,
      minute: reminder.minute,
      weekDays: reminder.weekDays,
      isEnabled: isEnabled,
      notificationId: reminder.notificationId
    );

    if (isEnabled) {
      await NotificationService().scheduleReminder(updated);
    } else {
      await NotificationService().cancelReminder(updated);
    }
  }

  Future<void> deleteReminder(StudyReminder reminder) async {
    if (_uid == null) return;

    await _db.collection('users').doc(_uid).collection('reminders').doc(reminder.id).delete();

    await NotificationService().cancelReminder(reminder);
  }

  // ==================================================
  // === SESSIONS & STATS (LỊCH SỬ HỌC) ===
  // ==================================================

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

    final userRef = _db.collection('users').doc(_uid);
    await userRef.update({
      'stats.totalHours': FieldValue.increment(duration.inHours > 0 ? duration.inHours : (duration.inMinutes / 60)),
    });

    await addNotification(
      title: 'Hoàn thành bài học',
      body: 'Bạn đã học $cardsLearned thẻ trong bài "$categoryName". Cố gắng phát huy nhé!',
      type: 'achievement',
    );
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

    String message = 'Bạn đạt $quizScore/$totalQuestions điểm.';
    if (quizScore == totalQuestions) message = 'Xuất sắc! Bạn đúng tất cả các câu hỏi!';

    await addNotification(
      title: 'Kết quả Quiz: $categoryName',
      body: message,
      type: 'achievement',
    );
  }

  Future<List<QueryDocumentSnapshot>> getRecentSessions(int limit) async {
    if (_uid == null) throw Exception("Chưa đăng nhập");

    var ref = _db.collection('users').doc(_uid).collection('sessions')
        .orderBy('timestamp', descending: true)
        .limit(limit);

    var snapshot = await ref.get();
    return snapshot.docs;
  }

  Future<List<Map<String, dynamic>>> getWeeklyStudyData() async {
    if (_uid == null) return [];

    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    final snapshot = await _db
        .collection('users')
        .doc(_uid)
        .collection('sessions')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(weekAgo))
        .get();

    List<Map<String, dynamic>> result = [];

    for (int i = 6; i >= 0; i--) {
      DateTime day = now.subtract(Duration(days: i));
      DateTime startOfDay = DateTime(day.year, day.month, day.day);
      DateTime endOfDay = DateTime(day.year, day.month, day.day, 23, 59, 59);

      double hours = 0;
      for (var doc in snapshot.docs) {
        DateTime timestamp = (doc['timestamp'] as Timestamp).toDate();
        if (timestamp.isAfter(startOfDay) && timestamp.isBefore(endOfDay)) {
           int durationSec = doc['duration'] ?? 0;
           hours += durationSec / 3600.0;
        }
      }

      result.add({
        'day': day,
        'hours': hours,
      });
    }

    return result;
  }
}