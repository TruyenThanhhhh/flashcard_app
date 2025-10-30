import 'package:flutter/material.dart';
import '../models/category.dart';
import '../screens/flashcards_screen.dart';
import '../screens/learning_screen.dart';
import '../screens/quiz_screen.dart';
import '../data/demo_data.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onToggleTheme;
  final bool isDark;
  const HomeScreen({super.key, this.onToggleTheme, this.isDark = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late List<Category> categories;
  int selectedTab = 0;
  bool _showTip = true;
  final List<Map<String,dynamic>> topicIcons = [
    {'icon': Icons.star, 'color': Colors.deepPurpleAccent},
    {'icon': Icons.pets, 'color': Colors.teal},
    {'icon': Icons.forum, 'color': Colors.orangeAccent},
  ];

  @override
  void initState() {
    super.initState();
    categories = demoCategories;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chủ đề từ vựng'),
        actions: [
          IconButton(
            icon: Icon(widget.isDark ? Icons.dark_mode : Icons.light_mode, color: Colors.yellow[300]),
            tooltip: 'Chuyển chế độ sáng/tối',
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedTab,
        onTap: (i) => setState(()=>selectedTab=i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label:'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label:'Thống kê'),
        ],
      ),
      body: selectedTab == 0 ? Stack(
        children: [
          ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: categories.length,
            itemBuilder: (context, idx) {
              final c = categories[idx];
              return Card(
                elevation: 5,
                margin: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: topicIcons[idx%topicIcons.length]['color'],
                    child: Icon(topicIcons[idx%topicIcons.length]['icon'], color: Colors.white),
                  ),
                  title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                ),
              );
            },
          ),
          if (_showTip)
            Positioned(
              left: 8,right:8,top:0,
              child: Card(
                color: Colors.amber[100],
                elevation: 7,
                margin: const EdgeInsets.all(12),
                child: ListTile(
                  leading: const Icon(Icons.info_outline, color: Colors.orange),
                  title: const Text('Mẹo: Bấm và giữ một chủ đề để tuỳ chọn “Học, Quiz, Quản lý” hoặc chạm vào biểu tượng ☰'),
                  trailing: IconButton(
                    icon: const Icon(Icons.close), onPressed: ()=>setState(()=>_showTip=false)),
                ),
              ),
            ),
        ],
      ) : _StatisticsPlaceholder(),
    );
  }
}

class _StatisticsPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Thống kê đang phát triển...', style: TextStyle(fontSize: 20)),
    );
  }
}
