import 'package:cloud_firestore/cloud_firestore.dart';

class StudyReminder {
  final String id;
  final String title;
  final int hour;
  final int minute;
  final List<int> weekDays; // 1=Thứ 2, ..., 7=CN
  final bool isEnabled;
  final int notificationId;

  StudyReminder({
    required this.id,
    required this.title,
    required this.hour,
    required this.minute,
    required this.weekDays,
    this.isEnabled = true,
    required this.notificationId,
  });

  // Chuyển đổi từ Firestore Document thành Object
  factory StudyReminder.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return StudyReminder(
      id: doc.id,
      title: data['title'] ?? 'Nhắc nhở học tập',
      hour: data['hour'] ?? 20,
      minute: data['minute'] ?? 0,
      
      // 🔥 FIX LỖI QUAN TRỌNG:
      // Dùng List<int>.from để copy và ép kiểu an toàn từ List<dynamic>
      weekDays: List<int>.from(data['weekDays'] ?? []),
      
      isEnabled: data['isEnabled'] ?? true,
      notificationId: data['notificationId'] ?? 0,
    );
  }

  // Chuyển đổi từ Object sang Map để lưu lên Firestore
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

  // Getter hiển thị giờ (Ví dụ: "08:05")
  String get timeString {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  // Getter hiển thị ngày lặp (Ví dụ: "T2, T4, CN" hoặc "Hàng ngày")
  String get daysString {
    if (weekDays.length == 7) return "Hàng ngày";
    if (weekDays.isEmpty) return "Một lần";
    
    // 1. Copy danh sách để không ảnh hưởng dữ liệu gốc
    // 2. Sắp xếp tăng dần (1->7) để T2 luôn đứng trước CN
    List<int> sortedDays = List.from(weekDays)..sort();
    
    final map = {1: 'T2', 2: 'T3', 3: 'T4', 4: 'T5', 5: 'T6', 6: 'T7', 7: 'CN'};
    return sortedDays.map((d) => map[d] ?? '').join(', ');
  }
}