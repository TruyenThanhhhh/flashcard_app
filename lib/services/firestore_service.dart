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

  // Lấy stream dữ liệu user để hiển thị real-time (Tên, Avatar, Stats...)
  Stream<DocumentSnapshot> getUserStream() {
    if (_uid == null) {
      return Stream.error(Exception("Chưa đăng nhập")); 
    }
    return _db.collection('users').doc(_uid).snapshots();
  }

  // ==================================================
  // === FLASHCARD SETS (BỘ THẺ) ===
  // ==================================================

  // Lấy danh sách bộ thẻ
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

  // Thêm bộ thẻ mới
  Future<void> addFlashcardSet(String title) async {
    if (_uid == null) throw Exception("Chưa đăng nhập");
    
    await _db.collection('users').doc(_uid).collection('flashcard_sets').add({
      'title': title,
      'description': '',
      'color': '#4CAF50', // Màu mặc định
      'cardCount': 0,
      'folder_id': 'root',
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    // Tự động tạo thông báo hệ thống
    await addNotification(
      title: 'Chủ đề mới',
      body: 'Bạn vừa tạo chủ đề "$title". Hãy thêm thẻ để bắt đầu học nhé!',
      type: 'system',
    );
  }

  // Đổi tên bộ thẻ
  Future<void> updateFlashcardSetTitle(String setId, String newTitle) async {
    if (_uid == null) throw Exception("Chưa đăng nhập");

    await _db
        .collection('users')
        .doc(_uid)
        .collection('flashcard_sets')
        .doc(setId)
        .update({'title': newTitle});
  }

  // Xóa bộ thẻ
  Future<void> deleteFlashcardSet(String setId) async {
    if (_uid == null) throw Exception("Chưa đăng nhập");
    
    final setRef = _db
        .collection('users')
        .doc(_uid)
        .collection('flashcard_sets')
        .doc(setId);
    
    // Lưu ý: Để xóa sạch các subcollection (cards) bên trong, 
    // lý tưởng nhất là dùng Cloud Functions. 
    // Ở đây ta xóa document cha, các con sẽ bị mồ côi (orphaned) nhưng không hiển thị nữa.
    await setRef.delete();
  }

  // ==================================================
  // === FLASHCARDS (THẺ HỌC) ===
  // ==================================================

  // Lấy danh sách thẻ (Real-time stream)
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

  // Lấy danh sách thẻ 1 lần (Dùng cho chế độ Học/Quiz để không bị nhảy khi update)
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

  // Thêm thẻ mới
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

    // Tăng số lượng thẻ trong bộ
    final setRef = _db
        .collection('users')
        .doc(_uid)
        .collection('flashcard_sets')
        .doc(setId);
    await setRef.update({'cardCount': FieldValue.increment(1)});
    
    // Tăng tổng số thẻ trong stats user
    final userRef = _db.collection('users').doc(_uid);
    await userRef.update({'stats.totalFlashcards': FieldValue.increment(1)});
  }

  // Sửa thẻ
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

  // Xóa thẻ
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
    
    // Giảm số lượng thẻ trong bộ
    final setRef = _db
        .collection('users')
        .doc(_uid)
        .collection('flashcard_sets')
        .doc(setId);
    await setRef.update({'cardCount': FieldValue.increment(-1)});
    
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

  // Lấy danh sách thông báo
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
  
  // Đếm số thông báo chưa đọc (để hiện badge đỏ)
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

  // Tạo thông báo mới
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

  // Đánh dấu 1 thông báo đã đọc
  Future<void> markNotificationAsRead(String notificationId) async {
    if (_uid == null) return;

    await _db
        .collection('users')
        .doc(_uid)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }
  
  // Đánh dấu TẤT CẢ đã đọc
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

  // Xóa thông báo
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
  // === REMINDERS (NHẮC NHỞ) - Đã thêm mới ===
  // ==================================================
  
  Stream<List<StudyReminder>> getRemindersStream() {
    if (_uid == null) return Stream.value([]);
    return _db.collection('users').doc(_uid).collection('reminders')
        .orderBy('hour').orderBy('minute')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => StudyReminder.fromFirestore(doc)).toList());
  }

  Future<void> addReminder(String title, int hour, int minute, List<int> weekDays) async {
    if (_uid == null) return;
    
    // Tạo ID ngẫu nhiên cho Notification
    int notificationId = Random().nextInt(100000); 
    
    DocumentReference docRef = await _db.collection('users').doc(_uid).collection('reminders').add({
      'title': title,
      'hour': hour,
      'minute': minute,
      'weekDays': weekDays,
      'isEnabled': true,
      'notificationId': notificationId,
    });
    
    // Lên lịch ngay lập tức
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
    
    // Cập nhật lại lịch (hàm schedule sẽ tự hủy lịch cũ và đặt lịch mới)
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
    
    // Hủy thông báo
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
    
    // Cập nhật tổng giờ học
    final userRef = _db.collection('users').doc(_uid);
    await userRef.update({
      'stats.totalHours': FieldValue.increment(duration.inHours > 0 ? duration.inHours : (duration.inMinutes / 60)),
    });
    
    // Tạo thông báo thành tích
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
    
    // Tạo thông báo kết quả Quiz
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

  // Lấy dữ liệu học trong 7 ngày gần nhất để vẽ biểu đồ
  Future<List<Map<String, dynamic>>> getWeeklyStudyData() async {
    if (_uid == null) return [];

    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    // Lấy tất cả session trong 7 ngày qua
    final snapshot = await _db
        .collection('users')
        .doc(_uid)
        .collection('sessions')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(weekAgo))
        .get();

    // Khởi tạo map cho 7 ngày (để đảm bảo ngày nào không học vẫn có data = 0)
    Map<int, double> dailyHours = {};
    for (int i = 0; i < 7; i++) {
      // Key là day (1=Mon, 7=Sun) hoặc index tùy chọn
      // Ở đây mình dùng ngày trong tháng để đơn giản hoặc weekday
      // Để vẽ biểu đồ theo thứ: 
      // Ta sẽ trả về list 7 phần tử, tương ứng từ [Hôm nay - 6] đến [Hôm nay]
    }
    
    // Cách đơn giản hơn cho UI:
    // Trả về List<double> hours, index 0 là 6 ngày trước, index 6 là hôm nay.
    List<Map<String, dynamic>> result = [];
    
    for (int i = 6; i >= 0; i--) {
      DateTime day = now.subtract(Duration(days: i));
      DateTime startOfDay = DateTime(day.year, day.month, day.day);
      DateTime endOfDay = DateTime(day.year, day.month, day.day, 23, 59, 59);
      
      // Lọc các session trong ngày này
      double hours = 0;
      for (var doc in snapshot.docs) {
        DateTime timestamp = (doc['timestamp'] as Timestamp).toDate();
        if (timestamp.isAfter(startOfDay) && timestamp.isBefore(endOfDay)) {
           int durationSec = doc['duration'] ?? 0;
           hours += durationSec / 3600.0;
        }
      }
      
      result.add({
        'day': day, // DateTime
        'hours': hours, // double
      });
    }
    
    return result;
  }
}