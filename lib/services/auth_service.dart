import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Import kIsWeb

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // --- ĐĂNG KÝ (Giữ nguyên) ---
  Future<UserCredential?> signUpWithEmail(
      String email, String password, String name, String username) async {
    try {
      final usernameQuery = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (usernameQuery.docs.isNotEmpty) {
        throw 'Username này đã tồn tại. Vui lòng chọn username khác.';
      }

      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _saveUserToFirestore(
          userCredential.user!, name, username);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw 'Email này đã được sử dụng. Vui lòng chọn email khác.';
      }
      throw e.message ?? 'Đã có lỗi xảy ra khi đăng ký.';
    } catch (e) {
      // Ném ra lỗi (ví dụ: "Username đã tồn tại")
      throw e.toString();
    }
  }

  // --- ĐĂNG NHẬP (Giữ nguyên) ---
  Future<UserCredential?> signInWithEmailOrUsername(
      String loginId, String password) async {
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
      return await _auth.signInWithEmailAndPassword(
          email: email, password: password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        throw 'Email/Username hoặc mật khẩu không đúng.';
      }
      throw e.message ?? 'Đã có lỗi xảy ra khi đăng nhập.';
    }
  }

  // --- ĐĂNG NHẬP GOOGLE (ĐÃ SỬA LỖI CHO WEB) ---
  Future<UserCredential?> signInWithGoogle() async {
    try {
      UserCredential userCredential;

      if (kIsWeb) {
        // --- LOGIC CHO WEB ---
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        // Bạn có thể thêm OAuth Client ID ở đây nếu cần,
        // nhưng thường Firebase tự xử lý sau khi chạy flutterfire configure
        // googleProvider.setCustomParameters({'login_hint': 'user@example.com'});
        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        // --- LOGIC CHO MOBILE (Android/iOS) ---
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

      // Sau khi có userCredential, lưu thông tin vào Firestore
      User? user = userCredential.user;
      if (user != null) {
        String username = user.email!.split('@').first;
        await _saveUserToFirestore(
            user, user.displayName ?? 'No Name', username);
      }
      return userCredential;

    } catch (e) {
      print("LỖI GOOGLE SIGN-IN THỰC TẾ: $e");
      // Hiển thị các lỗi phổ biến trên web
      if (e is FirebaseAuthException) {
        if (e.code == 'auth/popup-blocked-by-browser') {
           throw 'Trình duyệt đã chặn cửa sổ pop-up. Vui lòng cho phép pop-up cho trang này.';
        }
        if (e.code == 'auth/cancelled-popup-request') {
           throw 'Yêu cầu đăng nhập đã bị hủy.';
        }
      }
      throw 'Đã xảy ra lỗi khi đăng nhập Google. Vui lòng thử lại.';
    }
  }

  // --- ĐĂNG XUẤT (ĐÃ SỬA LỖI CHO WEB) ---
  Future<void> signOut() async {
    if (!kIsWeb) {
      // Chỉ chạy signOut của GoogleSignIn trên Mobile
      await _googleSignIn.signOut();
    }
    // Chạy signOut của Firebase trên mọi nền tảng
    await _auth.signOut();
  }

  // --- HÀM LƯU USER (Giữ nguyên) ---
  Future<void> _saveUserToFirestore(
      User user, String name, String username) async {
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'name': name,
      'username': username,
      'lastLogin': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'stats': {
        'totalFlashcards': 0,
        'totalNotes': 0,
        'streak': 0,
        'totalHours': 0,
      },
      'setting': {
        'language': 'vi',
        'notifications': true,
        'themeMode': 'light'
      }
    }, SetOptions(merge: true));
  }
}