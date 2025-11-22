import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/auth_wrapper.dart'; // SỬA: Import AuthWrapper

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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
  ThemeMode themeMode = ThemeMode.light;

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

      // --- Theme (SỬA: Đã xóa các 'const' không hợp lệ) ---
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        brightness: Brightness.light,
        scaffoldBackgroundColor: Color(0xFFF8FAFC),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        cardTheme: CardThemeData( // SỬA: Xóa const
          color: Colors.white,
          margin: const EdgeInsets.all(10), // 'const' ở đây thì OK
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18), // SỬA: Xóa const
          ),
          elevation: 2,
        ),
        appBarTheme: AppBarTheme( // SỬA: Xóa const
          backgroundColor: Colors.white,
          elevation: 1,
          scrolledUnderElevation: 1,
          iconTheme: const IconThemeData(color: Colors.black87), // 'const' ở đây thì OK
          titleTextStyle: const TextStyle( // SỬA: Xóa const
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
        textTheme: const TextTheme( // 'const' ở đây thì OK
          titleLarge: TextStyle(fontWeight: FontWeight.bold),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData( // SỬA: Xóa const
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // SỬA: Xóa const
          ),
        ),
        snackBarTheme: const SnackBarThemeData( // 'const' ở đây thì OK
          backgroundColor: Colors.indigo,
          contentTextStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      // --- DarkTheme (SỬA: Đã xóa các 'const' không hợp lệ) ---
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Color(0xFF0F172A),
        cardTheme: CardThemeData( // SỬA: Xóa const
          color: Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18), // SỬA: Xóa const
          ),
          elevation: 1,
        ),
        appBarTheme: const AppBarTheme( // 'const' ở đây thì OK
          backgroundColor: Color(0xFF1E293B),
          elevation: 1,
          scrolledUnderElevation: 1,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        textTheme: const TextTheme( // 'const' ở đây thì OK
          titleLarge:
              TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData( // SỬA: Xóa const
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // SỬA: Xóa const
          ),
        ),
      ),
      
      home: AuthWrapper(
        onToggleTheme: toggleTheme,
        isDark: themeMode == ThemeMode.dark,
      ),
    );
  }
}