import 'dart:async';
import 'package:flutter/material.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Chờ 3 giây rồi chuyển sang HomeScreen
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedOpacity(
          opacity: 1.0,
          duration: const Duration(seconds: 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo chính
              Image.asset(
                'images/StudyMateRemoveBG.png',
                width: 200,
              ),
              const SizedBox(height: 20),

              // Chữ "from"
              const Text(
                'from',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 6),

              // Logo nhóm / thương hiệu
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
