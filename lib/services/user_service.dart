// lib/services/user_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// SỬA: Hàm này giờ nhận thêm 1 username tùy chọn
Future<void> initializeUserData(User user, {String? username}) async {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final DocumentReference userDoc = db.collection('users').doc(user.uid);

  final docSnapshot = await userDoc.get();

  if (!docSnapshot.exists) {
    // --- 1. USER MỚI (Đăng ký) ---
    print("User mới, bắt đầu khởi tạo dữ liệu...");
    
    // Logic tạo username:
    // 1. Ưu tiên username do người dùng nhập lúc đăng ký
    // 2. Nếu không có (ví dụ: đăng nhập Google), dùng phần đầu email
    // 3. Nếu không có, dùng một phần uid
    final String defaultUsername =
        user.email?.split('@').first ?? 'user_${user.uid.substring(0, 6)}';
    
    // Dùng WriteBatch cho an toàn
    WriteBatch batch = db.batch();

    batch.set(userDoc, {
      'uid': user.uid,
      'email': user.email,
      'name': user.displayName ?? 'New User', // Lấy tên từ Google/Đăng ký
      'photoURL': user.photoURL, // Lấy Avatar URL từ Google
      'username': username ?? defaultUsername, // SỬA: Dùng logic username mới
      'createdAt': FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(), // Thêm lastLogin khi tạo
      'stats': {
        'totalFlashcards': 0,
        'totalNotes': 0,
        'streak': 1, // Bắt đầu chuỗi với 1 ngày
        'totalHours': 0.0, // SỬA: Dùng double
      },
      'setting': {
        'language': 'vi',
        'notification': true,
        'themeMode': 'system', // SỬA: 'system' là lựa chọn tốt hơn
      },
    });
    
    try {
      await batch.commit();
      print("Khởi tạo dữ liệu user mới thành công!");
    } catch (e) {
      print("Lỗi khi khởi tạo dữ liệu user: $e");
    }

  } else {
    // --- 2. USER CŨ (Đăng nhập) ---
    print("User cũ, cập nhật lastLogin...");
    
    // Chỉ cập nhật các trường cần thiết
    await userDoc.update({
      'lastLogin': FieldValue.serverTimestamp(),
      // Cập nhật tên/avatar nếu nó thay đổi từ Google
      'name': user.displayName,
      'photoURL': user.photoURL,
    });
  }
}