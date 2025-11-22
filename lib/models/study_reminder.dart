import 'package:cloud_firestore/cloud_firestore.dart';

class StudyReminder {
  final String id;
  final String title;
  final int hour;
  final int minute;
  final List<int> weekDays; // 1=Mon ... 7=Sun
  final bool isEnabled;
  final int notificationId; // ID dạng số để dùng cho LocalNotification

  StudyReminder({
    required this.id,
    required this.title,
    required this.hour,
    required this.minute,
    required this.weekDays,
    this.isEnabled = true,
    required this.notificationId,
  });

  factory StudyReminder.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return StudyReminder(
      id: doc.id,
      title: data['title'] ?? '',
      hour: data['hour'] ?? 20,
      minute: data['minute'] ?? 0,
      weekDays: List<int>.from(data['weekDays'] ?? []),
      isEnabled: data['isEnabled'] ?? true,
      notificationId: data['notificationId'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'hour': hour,
      'minute': minute,
      'weekDays': weekDays,
      'isEnabled': isEnabled,
      'notificationId': notificationId,
    };
  }
  
  // Tạo chuỗi thời gian hiển thị (VD: 20:05)
  String get timeString {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
  
  // Tạo chuỗi ngày hiển thị (VD: T2, T4, CN)
  String get daysString {
    if (weekDays.length == 7) return 'Hàng ngày';
    if (weekDays.isEmpty) return 'Một lần';
    
    final map = {1: 'T2', 2: 'T3', 3: 'T4', 4: 'T5', 5: 'T6', 6: 'T7', 7: 'CN'};
    List<String> days = weekDays.map((d) => map[d] ?? '').toList();
    days.sort();
    return days.join(', ');
  }
}