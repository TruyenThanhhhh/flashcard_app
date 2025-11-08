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
