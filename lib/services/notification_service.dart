import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'dart:io' show Platform;
import '../models/study_reminder.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Sử dụng ID cố định cho bản production
  static const String channelId = 'study_reminders_channel_final';
  static const String channelName = 'Nhắc nhở học tập';

  Future<void> init() async {
    tz.initializeTimeZones();
    
    try {
      final location = tz.getLocation('Asia/Ho_Chi_Minh');
      tz.setLocalLocation(location);
    } catch (e) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

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
    await _createNotificationChannel();
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      channelId, 
      channelName,
      description: 'Kênh thông báo quan trọng cho việc học',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> requestPermissions() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
        
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true, badge: true, sound: true,
        );

    await _checkExactAlarmPermission();
  }

  Future<void> _checkExactAlarmPermission() async {
    if (Platform.isAndroid) {
      final androidImplementation = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        final bool? granted = await androidImplementation.canScheduleExactNotifications();
        if (granted == false) {
          await androidImplementation.requestExactAlarmsPermission(); 
        }
      }
    }
  }

  Future<void> scheduleReminder(StudyReminder reminder) async {
    try {
      await cancelReminder(reminder);

      if (!reminder.isEnabled) return;
      
      // Đảm bảo quyền hẹn giờ chính xác đã được cấp
      await _checkExactAlarmPermission();

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        channelId, channelName,
        importance: Importance.max, 
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        fullScreenIntent: true, // Đánh thức màn hình
        styleInformation: BigTextStyleInformation(''),
      );
      
      const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

      if (reminder.weekDays.length == 7) {
        final scheduledTime = _nextInstanceOfTime(reminder.hour, reminder.minute);
        
        await flutterLocalNotificationsPlugin.zonedSchedule(
          reminder.notificationId,
          reminder.title,
          "Đến giờ học rồi! 📚",
          scheduledTime,
          platformDetails,
          androidScheduleMode: AndroidScheduleMode.alarmClock,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } else {
        for (int day in reminder.weekDays) {
          int subId = (reminder.notificationId * 10) + day;
          final scheduledTime = _nextInstanceOfDayAndTime(day, reminder.hour, reminder.minute);

          await flutterLocalNotificationsPlugin.zonedSchedule(
            subId,
            reminder.title,
            "Đến giờ học rồi! 📚",
            scheduledTime,
            platformDetails,
            androidScheduleMode: AndroidScheduleMode.alarmClock,
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          );
        }
      }
    } catch (e) {
      // Xử lý lỗi âm thầm hoặc gửi về crashlytics nếu cần
    }
  }

  Future<void> cancelReminder(StudyReminder reminder) async {
    try {
      await flutterLocalNotificationsPlugin.cancel(reminder.notificationId);
      for (int i = 1; i <= 7; i++) {
         await flutterLocalNotificationsPlugin.cancel((reminder.notificationId * 10) + i);
      }
    } catch (e) {
      // Bỏ qua lỗi hủy
    }
  }

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