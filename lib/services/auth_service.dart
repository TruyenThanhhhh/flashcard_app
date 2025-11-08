import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Thêm import này

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Lấy người dùng hiện tại
  User? get currentUser => _auth.currentUser;

  // Stream theo dõi trạng thái đăng nhập
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // --- ĐĂNG KÝ EMAIL/PASSWORD ---
  Future<UserCredential?> signUpWithEmail(
    String email,
    String password,
    String name,
    String username,
  ) async {
    try {
      final usernameQuery = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (usernameQuery.docs.isNotEmpty) {
        throw 'Username này đã tồn tại. Vui lòng chọn username khác.';
      }

      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Cập nhật profile của user trong Firebase Auth (để có displayName)
      await userCredential.user?.updateDisplayName(name);

      // Lưu thông tin (sẽ không có photoURL lúc này)
      await _saveUserToFirestore(userCredential.user!);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw 'Email này đã được sử dụng. Vui lòng chọn email khác.';
      }
      throw e.message ?? 'Đã có lỗi xảy ra khi đăng ký.';
    }
  }

  // --- ĐĂNG NHẬP BẰNG EMAIL HOẶC USERNAME ---
  Future<UserCredential?> signInWithEmailOrUsername(
    String loginId,
    String password,
  ) async {
    try {
      String email = loginId;

      if (!loginId.contains('@')) {
        final usernameQuery = await _firestore
            .collection('users')
            .where('username', isEqualTo: loginId)
            .limit(1)
            .get();

        if (usernameQuery.docs.isEmpty) {
          throw 'Không tìm thấy tài khoản với username này.';
        }
        email = usernameQuery.docs.first.data()['email'];
      }
      // Đăng nhập với email đã lấy được
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Cập nhật lastLogin khi đăng nhập
      await _saveUserToFirestore(userCredential.user!);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        throw 'Email/Username hoặc mật khẩu không đúng.';
      }
      throw e.message ?? 'Đã có lỗi xảy ra khi đăng nhập.';
    }
  }

  // --- ĐĂNG NHẬP GOOGLE (Đã cập nhật) ---
  Future<UserCredential?> signInWithGoogle() async {
    try {
      UserCredential? userCredential;

      if (kIsWeb) {
        // --- Logic cho WEB ---
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        // --- Logic cho Mobile (Android/iOS) ---
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null; // Người dùng hủy

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        userCredential = await _auth.signInWithCredential(credential);
      }

      if (userCredential == null || userCredential.user == null) {
        throw "Đăng nhập Google thất bại.";
      }

      // Lưu thông tin user (tên, avatar) vào Firestore
      await _saveUserToFirestore(userCredential.user!);

      return userCredential;
    } catch (e) {
      print("LỖI GOOGLE SIGN-IN THỰC TẾ: $e");
      throw e.toString();
    }
  }

  // --- ĐĂNG XUẤT ---
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // --- HÀM LƯU USER VÀO FIRESTORE (ĐÃ CẬP NHẬT) ---
  Future<void> _saveUserToFirestore(User user) async {
    // Tự động tạo username từ email nếu chưa có
    final docRef = _firestore.collection('users').doc(user.uid);
    final doc = await docRef.get();

    String username =
        user.email?.split('@').first ?? 'user_${user.uid.substring(0, 6)}';

    // Chỉ tạo các trường này nếu document chưa tồn tại (lần đăng ký đầu tiên)
    if (!doc.exists) {
      await docRef.set({
        'uid': user.uid,
        'email': user.email,
        'name': user.displayName ?? 'New User', // Lấy tên từ Google/Đăng ký
        'photoURL': user.photoURL, // Lấy Avatar URL từ Google
        'username': username,
        'createdAt': FieldValue.serverTimestamp(),
        'stats': {
          'totalFlashcards': 0,
          'totalNotes': 0,
          'streak': 1, // Bắt đầu chuỗi với 1 ngày
          'totalHours': 0,
        },
        'setting': {
          'language': 'vi',
          'notifications': true,
          'themeMode': 'light',
        },
        // Thêm lastLogin khi tạo
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } else {
      // Nếu đã tồn tại (đăng nhập), chỉ cập nhật các trường cần thiết
      await docRef.update({
        'lastLogin': FieldValue.serverTimestamp(),
        // Cập nhật tên/avatar nếu nó thay đổi từ Google
        'name': user.displayName,
        'photoURL': user.photoURL,
      });
    }
  }
}
