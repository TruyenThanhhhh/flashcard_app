import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> initializeUserData(User user, {String? username}) async {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final DocumentReference userDoc = db.collection('users').doc(user.uid);

  final docSnapshot = await userDoc.get();

  if (!docSnapshot.exists) {
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
        'streak': 1,
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
    print("User cũ, cập nhật lastLogin...");
    await userDoc.update({
      'lastLogin': FieldValue.serverTimestamp(),
      'name': user.displayName,
      'photoURL': user.photoURL,
    });
  }
}