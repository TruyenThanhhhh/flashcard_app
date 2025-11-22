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
        .where('cardCount', isGreaterThan: 0) // Only show lessons with flashcards
        .orderBy('cardCount', descending: true);
    
    return query.snapshots().map((snapshot) {
      var lessons = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // Create a FlashcardSet from public lesson data
        return FlashcardSet(
          id: data['lessonId'] ?? doc.id,
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          color: data['color'] ?? '#4CAF50',
          cardCount: data['cardCount'] ?? 0,
          folder_id: 'root',
          isPublic: true,
          userId: data['userId'],
          creatorName: data['creatorName'],
        );
      }).where((set) => set.cardCount > 0).toList(); // Additional filter to ensure no 0-card lessons
      
      // If search query provided, filter by title (case-insensitive) in memory
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lowerQuery = searchQuery.toLowerCase();
        lessons = lessons.where((lesson) => 
          lesson.title.toLowerCase().contains(lowerQuery)
        ).toList();
      }
      
      return lessons;
    });
  }

  // Thêm bộ thẻ mới
  Future<void> addFlashcardSet(String title, {bool isPublic = false}) async {
    if (_uid == null) throw Exception("Chưa đăng nhập");
    
    // Get user name for public lessons
    String? creatorName;
    if (isPublic) {
      final userDoc = await _db.collection('users').doc(_uid).get();
      final userData = userDoc.data();
      creatorName = userData?['name'] ?? 'Người dùng';
    }
    
    final setData = {
      'title': title,
      'description': '',
      'color': '#4CAF50',
      'cardCount': 0,
      'folder_id': 'root',
      'isPublic': isPublic,
      'createdAt': FieldValue.serverTimestamp(),
    };
    
    // Add to user's collection
    final docRef = await _db.collection('users').doc(_uid).collection('flashcard_sets').add(setData);
    
    // If public, also add to public lessons collection
    if (isPublic) {
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
    
    // Tự động tạo thông báo hệ thống
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
    
    // If this is a public lesson, also update the title in public_lessons
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
    
    // Update the isPublic field
    await setRef.update({'isPublic': isPublic});
    
    if (isPublic && !currentIsPublic) {
      // Making it public - add to public_lessons
      final userDoc = await _db.collection('users').doc(_uid).get();
      final userData = userDoc.data();
      final creatorName = userData?['name'] ?? 'Người dùng';
      
      // Check if entry already exists (shouldn't happen, but just in case)
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
        // Update existing entry with current cardCount
        await existingQuery.docs.first.reference.update({
          'cardCount': cardCount,
          'title': setData['title'] ?? '',
        });
      }
    } else if (!isPublic && currentIsPublic) {
      // Making it private - remove from public_lessons
      final publicLessonsQuery = await _db.collection('public_lessons')
          .where('lessonId', isEqualTo: setId)
          .where('userId', isEqualTo: _uid)
          .get();
      
      for (var doc in publicLessonsQuery.docs) {
        await doc.reference.delete();
      }
    } else if (isPublic && currentIsPublic) {
      // Already public - ensure public_lessons entry exists and is synced
      final publicLessonsQuery = await _db.collection('public_lessons')
          .where('lessonId', isEqualTo: setId)
          .where('userId', isEqualTo: _uid)
          .get();
      
      if (publicLessonsQuery.docs.isEmpty) {
        // Entry missing - create it
        final userDoc = await _db.collection('users').doc(_uid).get();
        final userData = userDoc.data();
        final creatorName = userData?['name'] ?? 'Người dùng';
        
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
        // Entry exists - sync cardCount
        await publicLessonsQuery.docs.first.reference.update({
          'cardCount': cardCount,
          'title': setData['title'] ?? '',
        });
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
    
    // Check if this is a public lesson and remove from public_lessons
    final setDoc = await setRef.get();
    final setData = setDoc.data();
    if (setData != null && setData['isPublic'] == true) {
      final publicLessonsQuery = await _db.collection('public_lessons')
          .where('lessonId', isEqualTo: setId)
          .where('userId', isEqualTo: _uid)
          .get();
      
      for (var doc in publicLessonsQuery.docs) {
        await doc.reference.delete();
      }
    }
    
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

    final setRef = _db
        .collection('users')
        .doc(_uid)
        .collection('flashcard_sets')
        .doc(setId);
    final setDoc = await setRef.get();
    final setData = setDoc.data();
    final isPublic = setData != null && setData['isPublic'] == true;

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

    // Tăng số lượng thẻ trong bộ
    await setRef.update({'cardCount': FieldValue.increment(1)});
    
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
    
    final setRef = _db
        .collection('users')
        .doc(_uid)
        .collection('flashcard_sets')
        .doc(setId);
    final setDocBefore = await setRef.get();
    final setDataBefore = setDocBefore.data();
    final isPublic = setDataBefore != null && setDataBefore['isPublic'] == true;
    
    await _db
        .collection('users')
        .doc(_uid)
        .collection('flashcard_sets')
        .doc(setId)
        .collection('cards')
        .doc(cardId)
        .delete();
    
    await setRef.update({'cardCount': FieldValue.increment(-1)});
    
    if (isPublic) {
      final setDocAfter = await setRef.get();
      final setDataAfter = setDocAfter.data();
      final newCardCount = (setDataAfter?['cardCount'] as num? ?? 0).toInt();
      
      final publicLessonsQuery = await _db.collection('public_lessons')
          .where('lessonId', isEqualTo: setId)
          .where('userId', isEqualTo: _uid)
          .get();
      
      if (publicLessonsQuery.docs.isNotEmpty) {
        await publicLessonsQuery.docs.first.reference.update({
          'cardCount': newCardCount,
        });
      }
    }
    
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

    // SỬA LỖI Ở ĐÂY: Bỏ dấu nháy đơn quanh tên tham số
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

    // SỬA LỖI Ở ĐÂY: Bỏ dấu nháy đơn quanh tên tham số
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

    // SỬA LỖI Ở ĐÂY
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

    // SỬA LỖI Ở ĐÂY: Bỏ dấu nháy đơn quanh tham số type
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