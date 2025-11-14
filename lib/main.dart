import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Giữ lại
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart'; // Chỉ cần import file này

// Hàm main đã được cập nhật
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Giữ lại .env nếu bạn cần
  await dotenv.load(fileName: ".env"); 

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  print("✅ Firebase Initialized!");
  
  runApp(const FlashcardApp());
}

class FlashcardApp extends StatefulWidget {
  const FlashcardApp({super.key});

  @override
  State<FlashcardApp> createState() => _FlashcardAppState();
}

class _FlashcardAppState extends State<FlashcardApp> {
  // Logic theme giữ nguyên
  ThemeMode themeMode = ThemeMode.system; // SỬA: Dùng 'system' làm mặc định

  void toggleTheme() {
    setState(() {
      if (themeMode == ThemeMode.system) {
        // Lấy theme hiện tại của hệ thống để quyết định
        final brightness = MediaQuery.of(context).platformBrightness;
        themeMode = brightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
      } else {
        themeMode =
            themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
      }
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        brightness: Brightness.light,
        scaffoldBackgroundColor: Color(0xFFF8FAFC), // Sửa: Dùng màu nhạt
        visualDensity: VisualDensity.adaptivePlatformDensity,
        cardTheme: const CardThemeData(
          color: Colors.white, // Sửa: Dùng màu trắng
          margin: EdgeInsets.all(10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
          elevation: 2, // Sửa: Giảm elevation
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white, // Sửa
          elevation: 1,
          scrolledUnderElevation: 1,
          iconTheme: IconThemeData(color: Colors.black87),
          titleTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black87, // Sửa
          ),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontWeight: FontWeight.bold),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white, // MỚI: Thêm màu icon
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
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Color(0xFF0F172A), // Sửa: Dùng màu nền tối
        cardTheme: const CardThemeData(
          color: Color(0xFF1E293B), // Sửa
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
          elevation: 1,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E293B), // Sửa
          elevation: 1,
          scrolledUnderElevation: 1,
          iconTheme: IconThemeData(color: Colors.white),
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
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
      ),
      // --- HẾT PHẦN THEME ---

      // SỬA: Đã xóa FutureBuilder và AuthWrapper
      // home: sẽ gọi thẳng SplashScreen và truyền logic theme vào
      home: SplashScreen(
        onToggleTheme: toggleTheme,
        isDark: themeMode == ThemeMode.dark ||
                (themeMode == ThemeMode.system &&
                    MediaQuery.of(context).platformBrightness == Brightness.dark),
      ),
    );
  }
}