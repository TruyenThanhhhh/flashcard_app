import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/category.dart';
import '../models/flashcart.dart'; // Đảm bảo tên file model là 'flashcart.dart' hoặc 'flashcard.dart'
import 'flashcards_screen.dart';
import 'learning_screen.dart';
import 'quiz_screen.dart';
import 'ai_assistant_screen.dart';
// THÊM IMPORT ĐỂ SỬ DỤNG AUTHSERVICE
import '../services/auth_service.dart';

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
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // User stats from Firestore
  int studyStreak = 0;
  int lessonsLearned = 0;

  // Categories from Firestore
  List<Category> categories = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    // Khi màn hình khởi động, tải cả hai
    _loadUserStats();
    _loadCategories();
  }

  // Hàm này lấy thông tin thống kê từ /users/{userId}
  Future<void> _loadUserStats() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final userDoc = await _db.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        final stats = data?['stats'] as Map<String, dynamic>? ?? {};
        setState(() {
          studyStreak = stats['streak'] as int? ?? 0;
          lessonsLearned = stats['totalHours'] as int? ?? 0;
        });
      }
    } catch (e) {
      print('Error loading user stats: $e');
    }
  }

  // Hàm này lấy danh sách các bộ flashcard từ /users/{userId}/flashcard_sets
  Future<void> _loadCategories() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          errorMessage = 'Vui lòng đăng nhập để xem flashcard';
          isLoading = false;
        });
        return;
      }

      // Fetch flashcard_sets from users/{userId}/flashcard_sets
      final flashcardSetsSnapshot = await _db
          .collection('users')
          .doc(user.uid)
          .collection('flashcard_sets')
          .get();

      final loadedCategories = <Category>[];

      // Với mỗi bộ (set), tải các thẻ (card) bên trong nó
      for (final setDoc in flashcardSetsSnapshot.docs) {
        final setData = setDoc.data();
        
        // Fetch flashcards from the sub-collection
        final flashcardsSnapshot = await setDoc.reference
            .collection('flashcards')
            .get();

        // Chuyển đổi dữ liệu thô (raw data) sang
        // đối tượng Flashcard
        final cards = flashcardsSnapshot.docs.map((cardDoc) {
          final cardData = cardDoc.data();
          // Đảm bảo các key ('en', 'vi') khớp với CSDL của bạn
          // Hoặc đổi thành 'frontText', 'backText' nếu bạn theo thiết kế CSDL mới
          return Flashcard(
            id: cardDoc.id,
            english: cardData['en'] ?? cardData['english'] ?? cardData['frontText'] ?? '',
            vietnamese: cardData['vi'] ?? cardData['vietnamese'] ?? cardData['backText'] ?? '',
            example: cardData['example'] ?? cardData['note'],
          );
        }).toList();

        // Chuyển đổi dữ liệu thô (raw data) sang
        // đối tượng Category
        loadedCategories.add(Category(
          id: setDoc.id,
          name: setData['title'] ?? setData['name'] ?? '',
          cards: cards,
        ));
      }

      setState(() {
        categories = loadedCategories;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Lỗi khi tải dữ liệu: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      drawer: _buildDrawer(context, isDark), // Drawer (hamburger menu)
      appBar: AppBar(
        // ... (Code AppBar giữ nguyên) ...
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
        centerTitle: true,
        title: Image.asset(
          'images/StudyMateRemoveBG.png',
          height: 32,
          fit: BoxFit.contain,
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
        // ... (Code BottomNavigationBar giữ nguyên) ...
        currentIndex: selectedTab,
        onTap: (i) => setState(() => selectedTab = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Thống kê'),
        ],
      ),
      // Body sẽ hiển thị nội dung chính
      body: selectedTab == 0 ? _buildHomeContent() : _buildStatistics(),
    );
  }

  // Widget này xây dựng nội dung chính của trang chủ
  Widget _buildHomeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 👤 Thông tin người dùng
          Row(
            // ... (Code Row thông tin user giữ nguyên) ...
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
            // ... (Code Row thống kê giữ nguyên) ...
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatCard('Chuỗi ngày học', studyStreak.toString(), Colors.pink[100]!),
              _buildStatCard('Số giờ học', lessonsLearned.toString(), Colors.green[100]!),
            ],
          ),
          const SizedBox(height: 25),

          // ----------------------------------------------------
          // 💡 PHẦN HIỂN THỊ DỮ LIỆU TỪ FIREBASE
          // ----------------------------------------------------
          // Hiển thị vòng quay loading
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            )
          // Hiển thị lỗi nếu có
          else if (errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadCategories, // Nút thử lại
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            )
          // Hiển thị "Chưa có chủ đề nào" (như ảnh image_e85943.png)
          else if (categories.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    const Icon(Icons.folder_open, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'Chưa có chủ đề nào',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tạo chủ đề mới để bắt đầu học',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          // Hiển thị danh sách các bộ flashcard (khi có dữ liệu)
          else ...[
            // 🕓 Gần đây
            _buildSectionHeader('Gần đây'),
            // Lấy 1 bộ
            ...categories.take(1).map((category) => _buildCourseCard(
                  category,
                  '${category.cards.length} thuật ngữ',
                  Colors.green[200]!,
                )),
            const SizedBox(height: 18),

            // 💡 Gợi ý bài học
            if (categories.length > 1) ...[
              _buildSectionHeader('Gợi ý bài học'),
              // Bỏ 1, lấy 1 bộ tiếp theo
              ...categories.skip(1).take(1).map((category) => _buildCourseCard(
                    category,
                    '${category.cards.length} thuật ngữ',
                    Colors.lightGreen[200]!,
                  )),
              const SizedBox(height: 18),
            ],

            // 📁 Thư mục của tôi
            if (categories.length > 2) ...[
              _buildSectionHeader('Thư mục của tôi'),
              // Bỏ 2, lấy tất cả còn lại
              ...categories.skip(2).map((category) => _buildCourseCard(
                    category,
                    '${category.cards.length} thuật ngữ',
                    Colors.lightGreen[200]!,
                  )),
            ],
          ],

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ... (Các hàm _buildStatCard, _buildSectionHeader, _buildCourseCard giữ nguyên) ...
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
  
  Widget _buildCourseCard(Category category, String subtitle, Color color) {
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
                  Text(category.name,
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

  // ... (Hàm _showCategoryOptions giữ nguyên) ...
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

  // ... (Hàm _buildOptionTile giữ nguyên) ...
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color, // Màu chữ trùng với màu icon
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14, // Cỡ chữ subtitle
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

  // ----------------------------------------------------
  // 💡 HÀM BUILD DRAWER (ĐÃ THÊM NÚT ĐĂNG XUẤT)
  // ----------------------------------------------------
  Widget _buildDrawer(BuildContext context, bool isDark) {
    // Khởi tạo AuthService để gọi hàm signOut
    final authService = AuthService();

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            // ... (Code DrawerHeader giữ nguyên) ...
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
                  // Lấy email của user đang đăng nhập
                  _auth.currentUser?.email ?? 'thanhhbinh@example.com',
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
              setState(() {
                selectedTab = 0;
              });
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
          // ----------------------------------------------------
          // 💡 ĐÃ THÊM NÚT ĐĂNG XUẤT
          // ----------------------------------------------------
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Đăng xuất', style: TextStyle(color: Colors.redAccent)),
            onTap: () {
              // 1. Đóng menu
              Navigator.pop(context);
              // 2. Gọi hàm signOut từ AuthService
              authService.signOut();
              // StreamBuilder trong main.dart sẽ tự động bắt
              // và chuyển về màn hình Login
            },
          ),
        ],
      ),
    );
  }
}