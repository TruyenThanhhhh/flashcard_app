import 'dart:async';
import 'package:flutter/material.dart';
// SỬA: Xóa các import không cần thiết
// import 'package:firebase_auth/firebase_auth.dart';
// import '../services/auth_service.dart';
// import 'home_screen.dart';
// import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  // SỬA: Xóa các tham số theme
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // SỬA: Xóa _auth
  // final AuthService _auth = AuthService();

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
      duration: const Duration(milliseconds: 1500),
    );

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
    _textSlide = Tween(begin: const Offset(0, 2), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.4, 0.8, curve: Curves.easeOutBack),
      ),
    );
    _vamosSlide = Tween(begin: const Offset(0, 2), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.5, 0.9, curve: Curves.easeOutBack),
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // SỬA: Xóa StreamBuilder
    // Chỉ trả về nội dung splash
    return _buildSplashContent();
  }

  Widget _buildSplashContent() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _logoScale,
              child: FadeTransition(
                opacity: _logoFade,
                child: Image.asset(
                  'assets/images/StudyMateRemoveBG.png', // Sửa đường dẫn nếu cần
                  width: 200,
                ),
              ),
            ),
            const SizedBox(height: 20),
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
            SlideTransition(
              position: _vamosSlide,
              child: FadeTransition(
                opacity: _controller.drive(CurveTween(curve: Interval(0.5, 0.9))),
                child: Image.asset(
                  'assets/images/LogoVamos.png', // Sửa đường dẫn nếu cần
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