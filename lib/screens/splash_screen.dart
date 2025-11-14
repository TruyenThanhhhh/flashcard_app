import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // SỬA: Dùng Firebase
import '../services/auth_service.dart'; // SỬA: Dùng AuthService
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback? onToggleTheme;
  final bool isDark;
  const SplashScreen({super.key, this.onToggleTheme, this.isDark = false});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // SỬA: Dùng AuthService
  final AuthService _auth = AuthService();
  bool _showLogos = false;

  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showLogos = true;
        });
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    // SỬA: Dùng StreamBuilder để tự động điều hướng
    return StreamBuilder<User?>(
      stream: _auth.authStateChanges, // Lắng nghe trạng thái đăng nhập
      builder: (context, snapshot) {
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
          return LoginScreen(
            onToggleTheme: widget.onToggleTheme,
            isDark: widget.isDark,
          );
        }
      },
    );
  }

  Widget _buildSplashContent() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedOpacity(
          opacity: _showLogos ? 1.0 : 0.0,
          duration: const Duration(seconds: 1),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'images/StudyMateRemoveBG.png',
                width: 200,
              ),
              const SizedBox(height: 20),

              Text(
                'from',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 15,
                  color: Colors.grey.withOpacity(0.6)
                ),
              ),
              const SizedBox(height: 5),

              Image.asset(
                'images/LogoVamos.png',
                width: 130,
              ),
            ],
          ),
        ),
      ),
    );
  }
}