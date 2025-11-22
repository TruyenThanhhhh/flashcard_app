import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/study_reminder.dart'; // Import model StudyReminder

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> requestPermissions() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // Hủy tất cả thông báo cũ trước khi đặt lịch mới
  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  // Hủy một thông báo cụ thể bằng ID (Dùng cho scheduleCustomNotification cũ)
  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  // --- CÁC HÀM MỚI CHO STUDY REMINDER (SỬA LỖI CHO FIRESTORE SERVICE) ---

  // Lên lịch cho một Reminder cụ thể (Hàm này FirestoreService đang gọi)
  Future<void> scheduleReminder(StudyReminder reminder) async {
    // Trước khi lên lịch, hủy các ID cũ của reminder này để tránh trùng lặp
    await cancelReminder(reminder);

    if (!reminder.isEnabled) return;

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'study_reminders', 'Lịch học',
      channelDescription: 'Thông báo nhắc nhở học tập',
      importance: Importance.max, priority: Priority.high,
    );
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    // Nếu lặp lại hàng ngày (hoặc không chọn ngày nào - mặc định nhắc hôm nay/mai)
    if (reminder.weekDays.length == 7) {
       await flutterLocalNotificationsPlugin.zonedSchedule(
        reminder.notificationId, // ID gốc
        reminder.title,
        "Đến giờ học rồi! 📚",
        _nextInstanceOfTime(reminder.hour, reminder.minute),
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } else {
      // Lên lịch cho từng ngày trong tuần
      for (int day in reminder.weekDays) {
        // Tạo ID con: ID gốc * 10 + ngày (để đảm bảo duy nhất)
        // VD: ID=100, Thứ 2 -> 1001, Thứ 3 -> 1002
        // Lưu ý: Đảm bảo ID gốc < 10000 để tránh xung đột quá lớn
        int subId = (reminder.notificationId * 10) + day;
        
        await flutterLocalNotificationsPlugin.zonedSchedule(
          subId,
          reminder.title,
          "Đến giờ học rồi! 📚",
          _nextInstanceOfDayAndTime(day, reminder.hour, reminder.minute),
          platformDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }
    }
  }

  // Hủy lịch của một Reminder (Hàm này FirestoreService đang gọi)
  Future<void> cancelReminder(StudyReminder reminder) async {
    // Hủy ID gốc (trường hợp hàng ngày)
    await flutterLocalNotificationsPlugin.cancel(reminder.notificationId);
    
    // Hủy các ID con (trường hợp chọn thứ)
    for (int i = 1; i <= 7; i++) {
       await flutterLocalNotificationsPlugin.cancel((reminder.notificationId * 10) + i);
    }
  }

  // --- CÁC HÀM CŨ (GIỮ LẠI ĐỂ TƯƠNG THÍCH NGƯỢC NẾU CẦN) ---

  // Lên lịch tùy chỉnh (Legacy)
  Future<void> scheduleCustomNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required List<int> weekDays, // [1 (Mon) -> 7 (Sun)]
  }) async {
    if (weekDays.isEmpty) return;
    // Logic cũ... (có thể tái sử dụng code ở trên hoặc bỏ qua nếu đã dùng StudyReminder)
    // Để đơn giản, ta tạo tạm một object StudyReminder và gọi hàm mới
    StudyReminder tempReminder = StudyReminder(
        id: 'temp_$id', 
        title: title, 
        hour: hour, 
        minute: minute, 
        weekDays: weekDays, 
        notificationId: id,
        isEnabled: true
    );
    await scheduleReminder(tempReminder);
  }

  // --- CÁC HÀM PHỤ TRỢ TÍNH TOÁN THỜI GIAN ---

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  tz.TZDateTime _nextInstanceOfDayAndTime(int dayOfWeek, int hour, int minute) {
    tz.TZDateTime scheduledDate = _nextInstanceOfTime(hour, minute);
    while (scheduledDate.weekday != dayOfWeek) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}