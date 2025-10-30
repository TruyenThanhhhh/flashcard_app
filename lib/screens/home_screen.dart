import 'package:flutter/material.dart';
import '../models/category.dart';
import '../screens/flashcards_screen.dart';
import '../screens/learning_screen.dart';
import '../screens/quiz_screen.dart';
import '../data/demo_data.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late List<Category> categories;

  @override
  void initState() {
    super.initState();
    categories = demoCategories; // từ demo_data.dart
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chủ đề từ vựng')),
      body: ListView.separated(
        itemCount: categories.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, idx) {
          final c = categories[idx];
          return ListTile(
            title: Text(c.name),
            subtitle: Text('${c.cards.length} flashcards'),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'learn') {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => LearningScreen(category: c),
                  ));
                } else if (value == 'manage') {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => FlashcardsScreen(category: c),
                  ));
                } else if (value == 'quiz') {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => QuizScreen(category: c),
                  ));
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem<String>(value: 'learn', child: Text('Chế độ học')), 
                const PopupMenuItem<String>(value: 'quiz', child: Text('Làm quiz/kiểm tra')), 
                const PopupMenuItem<String>(value: 'manage', child: Text('Quản lý/Cập nhật thẻ')), 
              ],
              icon: const Icon(Icons.more_vert),
            ),
            onTap: null,
          );
        },
      ),
    );
  }
}
