import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart'; // Import Login Screen
import 'services/auth_service.dart'; // Import Auth Service

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("✅ Firebase đã khởi tạo thành công!");
  } catch (e) {
    print("❌ Lỗi khi khởi tạo Firebase: $e");
  }
  runApp(const FlashcardApp());
}

class FlashcardApp extends StatefulWidget {
  const FlashcardApp({super.key});

  @override
  State<FlashcardApp> createState() => _FlashcardAppState();
}

class _FlashcardAppState extends State<FlashcardApp> {
  ThemeMode themeMode = ThemeMode.light;

  // Thêm một Future để giả lập thời gian chờ của Splash Screen
  final Future<void> _splashScreenDelay = Future.delayed(const Duration(seconds: 3));

  void toggleTheme() {
    setState(() {
      themeMode =
          themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StudyMate',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,

      // --- Theme và DarkTheme của bạn giữ nguyên ---
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        brightness: Brightness.light,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        cardTheme: const CardThemeData(
          color: Color(0xFFE8EAF6),
          margin: EdgeInsets.all(10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
          elevation: 4,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.indigo,
          elevation: 1,
          titleTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontWeight: FontWeight.bold),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.indigo,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Colors.indigo,
          contentTextStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: Colors.black,
        cardTheme: const CardThemeData(
          color: Color(0xFF212121),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
          elevation: 2,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 1,
          titleTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        textTheme: const TextTheme(
          titleLarge:
              TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      // --- HẾT PHẦN THEME ---

      // Sửa đổi 'home' để điều hướng logic
      home: FutureBuilder(
        future: _splashScreenDelay,
        builder: (context, snapshot) {
          // Khi Future đang chạy (đang chờ 3s), hiển thị SplashScreen
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }

          // Khi Future hoàn thành (đã chờ 3s), hiển thị AuthWrapper
          // AuthWrapper sẽ tự quyết định vào Login hay Home
          return const AuthWrapper();
        },
      ),
    );
  }
}

// Widget mới để kiểm tra trạng thái đăng nhập
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Dùng StreamBuilder để lắng nghe thay đổi trạng thái đăng nhập
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges, // Lấy stream từ AuthService
      builder: (context, snapshot) {
        // Đang chờ kết nối (ví dụ: đang lấy token)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Đã có dữ liệu
        if (snapshot.hasData) {
          // Nếu snapshot.data có dữ liệu (User), nghĩa là đã đăng nhập
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}