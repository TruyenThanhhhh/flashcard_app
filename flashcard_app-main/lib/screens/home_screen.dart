import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category.dart';
import '../data/demo_data.dart';
import 'flashcards_screen.dart';
import 'learning_screen.dart';
import 'quiz_screen.dart';
import 'ai_assistant_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onToggleTheme;
  final bool isDark;
  const HomeScreen({super.key, this.onToggleTheme, this.isDark = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedTab = 0;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Giả lập dữ liệu thống kê (có thể lấy từ Firestore user sau)
  int studyStreak = 8;
  int lessonsLearned = 24;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      drawer: _buildDrawer(context, isDark),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Colors.black87),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        title: Image.asset(
          'images/StudyMateRemoveBG.png',
          height: 40,
          fit: BoxFit.contain,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Colors.indigo),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AIAssistantScreen()),
              );
            },
            tooltip: 'AI Assistant',
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black87),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedTab,
        onTap: (i) => setState(() => selectedTab = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Thống kê'),
        ],
      ),
      body: selectedTab == 0 ? _buildHomeContent() : _buildStatistics(),
    );
  }

  Widget _buildHomeContent() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 👤 Thông tin người dùng
          Row(
            children: [
              const CircleAvatar(
                radius: 26,
                backgroundColor: Colors.green,
                child: Text('B',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24)),
              ),
              const SizedBox(width: 12),
              const Text(
                'Thanhh Binh',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode,
                    color: Colors.orangeAccent),
                onPressed: widget.onToggleTheme ?? () {
                  // If no callback provided, show a message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Theme toggle chưa được cấu hình')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 📊 Thống kê nhanh
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatCard('Chuỗi ngày học', studyStreak.toString(), Colors.pink[100]!),
              _buildStatCard('Số giờ học', lessonsLearned.toString(), Colors.green[100]!),
            ],
          ),
          const SizedBox(height: 25),

          // 🕓 Gần đây
          _buildSectionHeader('Gần đây'),
          _buildCourseCard(
            'Từ vựng cơ bản',
            '${demoCategories[0].cards.length} thuật ngữ',
            Colors.green[200]!,
            demoCategories[0],
          ),
          const SizedBox(height: 18),

          // 💡 Gợi ý bài học
          _buildSectionHeader('Gợi ý bài học'),
          _buildCourseCard(
            'Động vật',
            '${demoCategories[1].cards.length} thuật ngữ',
            Colors.lightGreen[200]!,
            demoCategories[1],
          ),
          const SizedBox(height: 18),

          // 📁 Thư mục của tôi
          _buildSectionHeader('Thư mục của tôi'),
          _buildCourseCard(
            'Giao tiếp',
            '${demoCategories[2].cards.length} thuật ngữ',
            Colors.lightGreen[200]!,
            demoCategories[2],
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // 🧩 Hàm dựng khối thống kê
  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(value,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  // 📘 Tiêu đề mục
  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        TextButton(
          onPressed: () {},
          child: const Text('Thêm',
              style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  // 🗂 Thẻ bài học
  Widget _buildCourseCard(String title, String subtitle, Color color, Category category) {
    return InkWell(
      onTap: () => _showCategoryOptions(context, category),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.menu_book_rounded, color: Colors.indigo, size: 34),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  if (subtitle.isNotEmpty)
                    Text(subtitle, style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showCategoryOptions(context, category),
            ),
          ],
        ),
      ),
    );
  }

  // Hiển thị menu lựa chọn cho category
  void _showCategoryOptions(BuildContext context, Category category) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  category.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${category.cards.length} flashcard',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                _buildOptionTile(
                  ctx,
                  icon: Icons.style,
                  title: 'Xem Flashcard',
                  subtitle: 'Xem và quản lý tất cả flashcard',
                  color: Colors.indigo,
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FlashcardsScreen(category: category),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildOptionTile(
                  ctx,
                  icon: Icons.school,
                  title: 'Chế độ học',
                  subtitle: 'Học và ghi nhớ flashcard',
                  color: Colors.green,
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LearningScreen(category: category),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildOptionTile(
                  ctx,
                  icon: Icons.quiz,
                  title: 'Làm Quiz',
                  subtitle: 'Kiểm tra kiến thức của bạn',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QuizScreen(category: category),
                      ),
                    );
                  },
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Drawer menu
  Widget _buildDrawer(BuildContext context, bool isDark) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo, Colors.indigo.shade700],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Text(
                    'B',
                    style: TextStyle(
                      color: Colors.indigo,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Thanhh Binh',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'thanhhbinh@example.com',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home, color: Colors.indigo),
            title: const Text('Trang chủ'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.auto_awesome, color: Colors.indigo),
            title: const Text('AI Assistant'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AIAssistantScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart, color: Colors.indigo),
            title: const Text('Thống kê'),
            onTap: () {
              Navigator.pop(context);
              setState(() {
                selectedTab = 1;
              });
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              color: Colors.indigo,
            ),
            title: Text(isDark ? 'Chế độ sáng' : 'Chế độ tối'),
            onTap: () {
              Navigator.pop(context);
              if (widget.onToggleTheme != null) {
                widget.onToggleTheme!();
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.indigo),
            title: const Text('Cài đặt'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.help_outline, color: Colors.indigo),
            title: const Text('Trợ giúp'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 18),
          ],
        ),
      ),
    );
  }

  // 📈 Trang thống kê
  Widget _buildStatistics() {
    return const Center(
      child: Text(
        "Thống kê đang phát triển...",
        style: TextStyle(fontSize: 20),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
            ? (isDark ? Color(0xFF6366F1).withOpacity(0.2) : Color(0xFF6366F1).withOpacity(0.1))
            : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected 
                ? Color(0xFF6366F1)
                : (isDark ? Colors.grey[500] : Colors.grey[600]),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Color(0xFF6366F1),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}