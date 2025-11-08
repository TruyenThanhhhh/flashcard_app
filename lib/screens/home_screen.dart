import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/category.dart';
import '../models/flashcart.dart';
import 'flashcards_screen.dart';
import 'learning_screen.dart';
import 'quiz_screen.dart';
import 'ai_assistant_screen.dart';
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
  
  // --- Biến State cho dữ liệu động ---
  String userName = "Đang tải...";
  String? userPhotoURL;
  String userEmail = "";
  int studyStreak = 0;
  int totalHours = 0;

  List<Category> categories = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Tải dữ liệu người dùng VÀ tính chuỗi ngày
    _loadCategories(); // Tải danh sách flashcard
  }

  /// Tải thông tin người dùng VÀ tính toán chuỗi ngày học
  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final userDocRef = _db.collection('users').doc(user.uid);
      final userDoc = await userDocRef.get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        final stats = data['stats'] as Map<String, dynamic>? ?? {};

        // --- 1. CẬP NHẬT TÊN VÀ AVATAR ---
        setState(() {
          userName = data['name'] as String? ?? 'No Name';
          userPhotoURL = data['photoURL'] as String?;
          userEmail = data['email'] as String? ?? '';
          totalHours = stats['totalHours'] as int? ?? 0;
        });

        // --- 2. LOGIC TÍNH CHUỖI NGÀY HỌC ---
        final lastLoginTimestamp = data['lastLogin'] as Timestamp?;
        if (lastLoginTimestamp == null) return; // Bỏ qua nếu không có lastLogin

        final lastLoginDate = lastLoginTimestamp.toDate();
        final now = DateTime.now();

        final currentStreak = stats['streak'] as int? ?? 0;

        // Dùng DateUtils để so sánh ngày (bỏ qua giờ, phút, giây)
        if (DateUtils.isSameDay(lastLoginDate, now)) {
          // Đã đăng nhập hôm nay -> không làm gì cả, giữ nguyên chuỗi
          setState(() {
            studyStreak = currentStreak;
          });
        } else {
          // Chưa đăng nhập hôm nay -> kiểm tra xem có phải hôm qua không
          final yesterday = now.subtract(const Duration(days: 1));
          
          if (DateUtils.isSameDay(lastLoginDate, yesterday)) {
            // Đăng nhập hôm qua -> Chuỗi tăng lên 1
            final newStreak = currentStreak + 1;
            setState(() {
              studyStreak = newStreak;
            });
            // Cập nhật streak VÀ lastLogin lên Firestore
            await userDocRef.update({
              'stats.streak': newStreak,
              'lastLogin': FieldValue.serverTimestamp(),
            });
          } else {
            // Bị ngắt chuỗi -> Đặt lại chuỗi = 1 (cho ngày hôm nay)
            setState(() {
              studyStreak = 1;
            });
            // Cập nhật streak = 1 VÀ lastLogin lên Firestore
            await userDocRef.update({
              'stats.streak': 1,
              'lastLogin': FieldValue.serverTimestamp(),
            });
          }
        }
      }
    } catch (e) {
      print('Lỗi khi tải dữ liệu người dùng: $e');
      setState(() {
        userName = "Lỗi tải tên";
      });
    }
  }

  Future<void> _loadCategories() async {
    // ... (Hàm này giữ nguyên như cũ, không thay đổi) ...
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

      final flashcardSetsSnapshot = await _db
          .collection('users')
          .doc(user.uid)
          .collection('flashcard_sets')
          .get();

      final loadedCategories = <Category>[];

      for (final setDoc in flashcardSetsSnapshot.docs) {
        final setData = setDoc.data();
        
        final flashcardsSnapshot = await setDoc.reference
            .collection('flashcards')
            .get();

        final cards = flashcardsSnapshot.docs.map((cardDoc) {
          final cardData = cardDoc.data();
          return Flashcard(
            id: cardDoc.id,
            english: cardData['en'] ?? cardData['english'] ?? cardData['frontText'] ?? '',
            vietnamese: cardData['vi'] ?? cardData['vietnamese'] ?? cardData['backText'] ?? '',
            example: cardData['example'] ?? cardData['note'],
          );
        }).toList();

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
      drawer: _buildDrawer(context, isDark),
      appBar: AppBar(
        // ... (Giữ nguyên AppBar) ...
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
        // ... (Giữ nguyên BottomNavigationBar) ...
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
          // --- 👤 Thông tin người dùng (ĐÃ CẬP NHẬT) ---
          Row(
            children: [
              // --- AVATAR ĐỘNG ---
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.green,
                // Nếu có link ảnh thì dùng, nếu không thì dùng chữ cái đầu
                backgroundImage: (userPhotoURL != null && userPhotoURL!.isNotEmpty)
                    ? NetworkImage(userPhotoURL!)
                    : null,
                child: (userPhotoURL != null && userPhotoURL!.isNotEmpty)
                    ? null
                    : Text(
                        (userName.isNotEmpty) ? userName[0].toUpperCase() : '?',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 24),
                      ),
              ),
              const SizedBox(width: 12),
              // --- TÊN ĐỘNG ---
              Text(
                userName, // Dùng biến `userName`
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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

          // --- 📊 Thống kê nhanh (ĐÃ CẬP NHẬT) ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatCard('Chuỗi ngày học', studyStreak.toString(), Colors.pink[100]!),
              _buildStatCard('Số giờ học', totalHours.toString(), Colors.green[100]!),
            ],
          ),
          const SizedBox(height: 25),

          // ... (Phần hiển thị loading/error/danh sách giữ nguyên) ...
           if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            )
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
                      onPressed: _loadCategories,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            )
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
          else ...[
            _buildSectionHeader('Gần đây'),
            ...categories.take(1).map((category) => _buildCourseCard(
                  category,
                  '${category.cards.length} thuật ngữ',
                  Colors.green[200]!,
                )),
            const SizedBox(height: 18),
            if (categories.length > 1) ...[
              _buildSectionHeader('Gợi ý bài học'),
              ...categories.skip(1).take(1).map((category) => _buildCourseCard(
                    category,
                    '${category.cards.length} thuật ngữ',
                    Colors.lightGreen[200]!,
                  )),
              const SizedBox(height: 18),
            ],
            if (categories.length > 2) ...[
              _buildSectionHeader('Thư mục của tôi'),
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

  // ... (Các hàm _buildStatCard, _buildSectionHeader, _buildCourseCard, _showCategoryOptions, _buildOptionTile, _buildStatistics giữ nguyên) ...
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
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
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

  Widget _buildStatistics() {
    return const Center(
      child: Text(
        "Thống kê đang phát triển...",
        style: TextStyle(fontSize: 20),
      ),
    );
  }

  // --- Drawer menu (ĐÃ CẬP NHẬT) ---
  Widget _buildDrawer(BuildContext context, bool isDark) {
    final authService = AuthService();

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
                // --- AVATAR ĐỘNG TRONG DRAWER ---
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  backgroundImage: (userPhotoURL != null && userPhotoURL!.isNotEmpty)
                      ? NetworkImage(userPhotoURL!)
                      : null,
                  child: (userPhotoURL != null && userPhotoURL!.isNotEmpty)
                      ? null
                      : Text(
                          (userName.isNotEmpty) ? userName[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: Colors.indigo,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 12),
                // --- TÊN ĐỘNG TRONG DRAWER ---
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                // --- EMAIL ĐỘNG TRONG DRAWER ---
                Text(
                  userEmail,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // ... (Các ListTile khác giữ nguyên) ...
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
          // Nút đăng xuất (đã có từ lần trước)
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Đăng xuất', style: TextStyle(color: Colors.redAccent)),
            onTap: () {
              Navigator.pop(context);
              authService.signOut();
            },
          ),
        ],
      ),
    );
  }
}