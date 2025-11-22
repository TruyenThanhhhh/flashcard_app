import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'splash_screen.dart'; // Import SplashScreen

class AuthWrapper extends StatefulWidget {
  final VoidCallback? onToggleTheme;
  final bool isDark;
  const AuthWrapper({super.key, this.onToggleTheme, this.isDark = false});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late Future<void> _splashTimer;
  late Stream<User?> _authStream;

  @override
  void initState() {
    super.initState();
    // 1. Đảm bảo splash screen hiển thị ít nhất 2 giây (sửa lỗi "không có splash")
    _splashTimer = Future.delayed(const Duration(seconds: 2));
    // 2. Bắt đầu lắng nghe trạng thái auth
    _authStream = AuthService().authStateChanges;
  }

  @override
  Widget build(BuildContext context) {
    // Dùng FutureBuilder để chờ Timer
    return FutureBuilder(
      future: _splashTimer,
      builder: (context, timerSnapshot) {
        // Dùng StreamBuilder để chờ Auth
        return StreamBuilder<User?>(
          stream: _authStream,
          builder: (context, authSnapshot) {
            
            // NẾU MỘT TRONG HAI CHƯA XONG:
            // (Timer chưa xong HOẶC Auth chưa kết nối)
            // => Hiển thị SplashScreen
            if (timerSnapshot.connectionState == ConnectionState.waiting ||
                authSnapshot.connectionState == ConnectionState.waiting) {
              
              // SplashScreen giờ không cần tham số
              return const SplashScreen(); 
            }

            // NẾU CẢ HAI ĐỀU XONG:
            // 1. Đã đăng nhập
            if (authSnapshot.hasData) {
              return HomeScreen(
                onToggleTheme: widget.onToggleTheme,
                isDark: widget.isDark,
              );
            }
            
            // 2. Chưa đăng nhập
            // Đây là nơi sửa lỗi "bàn phím"
            // Vì LoginScreen không còn bị bọc bởi StreamBuilder nữa
            return const LoginScreen();
          },
        );
      },
    );
  }
}