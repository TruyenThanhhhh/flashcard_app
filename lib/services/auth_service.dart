import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'user_service.dart'; 

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

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

      await userCredential.user?.updateDisplayName(name);
      await userCredential.user?.reload(); 
      final user = _auth.currentUser;

      if (user != null) {
        await initializeUserData(user, username: username);
      }
      
      return userCredential;
      
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw 'Email này đã được sử dụng. Vui lòng chọn email khác.';
      }
      throw e.message ?? 'Đã có lỗi xảy ra khi đăng ký.';
    }
  }

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
      
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        await initializeUserData(userCredential.user!);
      }
      
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

  Future<UserCredential?> signInWithGoogle() async {
    try {
      UserCredential? userCredential;

      if (kIsWeb) {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null;

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

      await initializeUserData(userCredential.user!);

      return userCredential;
      
    } catch (e) {
      print("LỖI GOOGLE SIGN-IN THỰC TẾ: $e");
      throw e.toString();
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}