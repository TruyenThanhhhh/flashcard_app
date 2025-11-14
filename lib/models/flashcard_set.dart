// lib/screens/splash_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback? onToggleTheme;
  final bool isDark;
  const SplashScreen({super.key, this.onToggleTheme, this.isDark = false});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

// SỬA: Thêm "with SingleTickerProviderStateMixin" để làm animation
class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _auth = AuthService();

  // SỬA: Các biến cho animation
  late AnimationController _controller;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<Offset> _textSlide;
  late Animation<Offset> _vamosSlide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500), // Tổng thời gian animation
    );

    // Logo StudyMate: Mờ dần VÀ Phóng to (từ 0.0s đến 0.9s)
    _logoFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );
    _logoScale = Tween(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    // Chữ "from": Trượt lên (từ 0.6s đến 1.2s)
    _textSlide = Tween(begin: const Offset(0, 2), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.4, 0.8, curve: Curves.easeOutBack),
      ),
    );

    // Logo VAMOS: Trượt lên (từ 0.8s đến 1.4s)
    _vamosSlide = Tween(begin: const Offset(0, 2), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.5, 0.9, curve: Curves.easeOutBack),
      ),
    );

    // Bắt đầu animation
    _controller.forward();
    
    // BỎ: Timer(const Duration(seconds: 3), ...)
    // Chúng ta không cần timer nữa, StreamBuilder sẽ tự xử lý
  }

  @override
  void dispose() {
    _controller.dispose(); // Hủy controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _auth.authStateChanges,
      builder: (context, snapshot) {
        //
        // SỬA LOGIC:
        // 1. Nếu đang chờ (waiting), HIỂN THỊ splash animation
        // 2. Nếu đã xong (active), MỚI điều hướng
        //
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSplashContent();
        }

        if (snapshot.hasData) {
          // Đã đăng nhập
          return HomeScreen(
            onToggleTheme: widget.onToggleTheme,
            isDark: widget.isDark,
          );
        } else {
          // Chưa đăng nhập
          // SỬA: Xóa các tham số không hợp lệ
          return const LoginScreen(
            // onToggleTheme: widget.onToggleTheme, // LỖI
            // isDark: widget.isDark, // LỖI
          );
        }
      },
    );
  }

  Widget _buildSplashContent() {
    return Scaffold(
      backgroundColor: Colors.white, // Luôn là nền trắng cho logo
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // SỬA: Dùng ScaleTransition và FadeTransition
            ScaleTransition(
              scale: _logoScale,
              child: FadeTransition(
                opacity: _logoFade,
                child: Image.asset(
                  'assets/StudyMateRemoveBG.png', // SỬA: Giả sử đường dẫn
                  width: 200,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // SỬA: Dùng SlideTransition
            SlideTransition(
              position: _textSlide,
              child: FadeTransition(
                opacity: _controller.drive(CurveTween(curve: Interval(0.4, 0.8))),
                child: Text(
                  'from',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 15,
                    color: Colors.grey.withOpacity(0.6),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),

            // SỬA: Dùng SlideTransition
            SlideTransition(
              position: _vamosSlide,
              child: FadeTransition(
                opacity: _controller.drive(CurveTween(curve: Interval(0.5, 0.9))),
                child: Image.asset(
                  'assets/LogoVamos.png', // SỬA: Giả sử đường dẫn
                  width: 130,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}