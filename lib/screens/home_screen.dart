import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category.dart';
import 'flashcards_screen.dart';
import 'learning_screen.dart';
import 'quiz_screen.dart';

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
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "studyMate",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
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
                icon: Icon(widget.isDark ? Icons.dark_mode : Icons.light_mode,
                    color: Colors.orangeAccent),
                onPressed: widget.onToggleTheme,
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
          _buildCourseCard('Minna no nihongo 3', '30 thuật ngữ', Colors.green[200]!),
          const SizedBox(height: 18),

          // 💡 Gợi ý bài học
          _buildSectionHeader('Gợi ý bài học'),
          _buildCourseCard('IELTS Rate 7.0 Vocab', '50 thuật ngữ', Colors.lightGreen[200]!),
          const SizedBox(height: 18),

          // 📁 Thư mục của tôi
          _buildSectionHeader('Thư mục của tôi'),
          _buildCourseCard('Ghi chú 1', '', Colors.lightGreen[200]!),

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

  Widget _buildCourseCard(String title, String subtitle, Color color) {
    return Container(
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
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    return const Center(
      child: Text(
        "Thống kê đang phát triển...",
        style: TextStyle(fontSize: 20),
      ),
    );
  }
}
