import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart'; // Để dùng DateUtils

Future<void> initializeUserData(User user, {String? username}) async {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final DocumentReference userDoc = db.collection('users').doc(user.uid);

  final docSnapshot = await userDoc.get();

  if (!docSnapshot.exists) {
    // --- 1. USER MỚI (Đăng ký) ---
    print("User mới, bắt đầu khởi tạo dữ liệu...");
    
    final String defaultUsername =
        user.email?.split('@').first ?? 'user_${user.uid.substring(0, 6)}';
    
    WriteBatch batch = db.batch();

    batch.set(userDoc, {
      'uid': user.uid,
      'email': user.email,
      'name': user.displayName ?? 'New User',
      'photoURL': user.photoURL,
      'username': username ?? defaultUsername,
      'createdAt': FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(), 
      'stats': {
        'totalFlashcards': 0,
        'totalNotes': 0,
        'streak': 1, // Bắt đầu là 1
        'totalHours': 0.0,
      },
      'setting': {
        'language': 'vi',
        'notification': true,
        'themeMode': 'system',
      },
    });
    
    try {
      await batch.commit();
      print("Khởi tạo dữ liệu user mới thành công!");
    } catch (e) {
      print("Lỗi khi khởi tạo dữ liệu user: $e");
    }

  } else {
    // --- 2. USER CŨ (Đăng nhập/Mở app) - TÍNH STREAK ---
    print("User cũ, kiểm tra streak...");
    
    final data = docSnapshot.data() as Map<String, dynamic>;
    final stats = data['stats'] as Map<String, dynamic>? ?? {};
    
    // Lấy ngày đăng nhập cuối cùng
    Timestamp? lastLoginTs = data['lastLogin'];
    DateTime lastLoginDate = lastLoginTs?.toDate() ?? DateTime(2000);
    DateTime now = DateTime.now();

    int currentStreak = stats['streak'] ?? 0;

    // Dùng DateUtils.isSameDay để so sánh (bỏ qua giờ phút)
    if (DateUtils.isSameDay(lastLoginDate, now)) {
      // Đã đăng nhập hôm nay -> Giữ nguyên
    } else {
      // Kiểm tra xem có phải hôm qua không
      final yesterday = now.subtract(const Duration(days: 1));
      if (DateUtils.isSameDay(lastLoginDate, yesterday)) {
        // Đăng nhập liên tiếp -> Tăng streak
        currentStreak++;
      } else {
        // Bị ngắt quãng -> Reset về 1 (ngày hôm nay)
        currentStreak = 1;
      }
    }

    // Cập nhật lại vào DB
    await userDoc.update({
      'lastLogin': FieldValue.serverTimestamp(),
      'name': user.displayName, // Cập nhật tên nếu có đổi
      'photoURL': user.photoURL, // Cập nhật avatar nếu có đổi
      'stats.streak': currentStreak,
    });
  }
}