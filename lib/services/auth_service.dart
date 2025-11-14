import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
// Facebook auth is temporarily disabled for Windows build
// import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Lấy stream theo dõi trạng thái đăng nhập
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Lấy người dùng hiện tại
  User? get currentUser => _firebaseAuth.currentUser;

  // Đăng nhập bằng Google
  Future<User?> signInWithGoogle() async {
    try {
      // Configure Google Sign-In for Windows (uses web-based OAuth)
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );
      
      // Sign out first to ensure clean state
      await googleSignIn.signOut();
      
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return null; // Người dùng hủy
      }
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw Exception('Không thể lấy thông tin xác thực từ Google');
      }
      
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      print('Google Sign-In Error: $e');
      rethrow;
    }
  }

  // Đăng nhập bằng Facebook
  // NOTE: Facebook auth is temporarily disabled for Windows build
  // Uncomment the import and this code after installing ATL in Visual Studio
  Future<User?> signInWithFacebook() async {
    throw UnimplementedError(
      'Facebook authentication is currently disabled. '
      'Please uncomment flutter_facebook_auth in pubspec.yaml and install ATL in Visual Studio to enable it.'
    );
    // try {
    //   final LoginResult result = await FacebookAuth.instance.login();
    //   if (result.status == LoginStatus.success) {
    //     final AccessToken accessToken = result.accessToken!;
    //     final AuthCredential credential = FacebookAuthProvider.credential(accessToken.tokenString);
    //     final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
    //     return userCredential.user;
    //   }
    //   return null;
    // } catch (e) {
    //   print(e);
    //   rethrow;
    // }
  }

  // Đăng nhập bằng Email/Password
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code); 
    }
  }

  // Đăng ký bằng Email/Password
  Future<User?> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
    String? displayName,
  }) async {
    try {
      final UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      if (user != null) {
        if (displayName != null && displayName.isNotEmpty) {
          await user.updateDisplayName(displayName);
        }
        await _saveUserProfile(
          user: user,
          username: username,
          displayName: displayName ?? user.displayName,
        );
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  // Đăng xuất
  Future<void> signOut() async {
    try {
      // Sign out from Google
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
    } catch (e) {
      print('Google Sign-Out Error: $e');
      // Continue with Firebase sign out even if Google sign out fails
    }
    
    // Facebook auth is disabled, so skip logout
    // try {
    //   await FacebookAuth.instance.logOut();
    // } catch (_) {} // Bỏ qua lỗi nếu chưa bật
    
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      print('Firebase Sign-Out Error: $e');
      rethrow; // Re-throw Firebase sign out errors as they're critical
    }
  }

  Future<void> _saveUserProfile({
    required User user,
    required String username,
    String? displayName,
  }) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    final snapshot = await docRef.get();
    final now = FieldValue.serverTimestamp();

    await docRef.set({
      'username': username,
      'username_lower': username.toLowerCase(),
      'email': user.email,
      'displayName': displayName ?? user.displayName ?? '',
      'updatedAt': now,
      if (!snapshot.exists) 'createdAt': now,
    }, SetOptions(merge: true));
  }

  Future<bool> isUsernameTaken(String username) async {
    final snapshot = await _firestore
        .collection('users')
        .where('username_lower', isEqualTo: username.toLowerCase())
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Future<String?> getEmailByUsername(String username) async {
    if (username.isEmpty) return null;
    final snapshot = await _firestore
        .collection('users')
        .where('username_lower', isEqualTo: username.toLowerCase())
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return snapshot.docs.first.data()['email'] as String?;
  }

  Future<void> ensureUserProfile({
    required User user,
    required String fallbackUsername,
  }) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    final doc = await docRef.get();
    if (!doc.exists || (doc.data()?['username'] as String?) == null) {
      await _saveUserProfile(
        user: user,
        username: fallbackUsername,
        displayName: user.displayName,
      );
    }
  }
}