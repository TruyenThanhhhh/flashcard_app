import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/flashcard_set.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import 'flashcards_screen.dart';
import 'learning_screen.dart';
import 'quiz_mode_selection_screen.dart';
import 'ai_assistant_screen.dart';
import 'settings_screen.dart';
import 'help_screen.dart';
import 'notes_list_screen.dart';
import 'note_editor_screen.dart'; // MỚI: Import để mở màn hình tạo ghi chú

class HomeScreen extends StatefulWidget {
  final VoidCallback? onToggleTheme;
  final bool isDark;
  const HomeScreen({super.key, this.onToggleTheme, this.isDark = false});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedTab = 0;
  
  final FirestoreService _db = FirestoreService();
  final AuthService _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    
    return StreamBuilder<DocumentSnapshot>(
      stream: _db.getUserStream(),
      builder: (context, userSnapshot) {
        
        String userName = "Đang tải...";
        String? userPhotoURL;
        String userEmail = "";
        int studyStreak = 0;
        double totalHours = 0.0; 

        if (userSnapshot.connectionState == ConnectionState.active && userSnapshot.hasData) {
          final data = userSnapshot.data!.data() as Map<String, dynamic>? ?? {};
          final stats = data['stats'] as Map<String, dynamic>? ?? {};
          userName = data['name'] ?? 'New User';
          userPhotoURL = data['photoURL'];
          userEmail = data['email'] ?? '';
          studyStreak = stats['streak'] ?? 0;
          totalHours = (stats['totalHours'] as num? ?? 0.0).toDouble(); 
        }

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.grey[100],
          drawer: _buildDrawer(context, isDark, userName, userEmail, userPhotoURL),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Builder(
              builder: (BuildContext context) {
                return IconButton(
                  icon: Icon(
                    Icons.menu,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                );
              },
            ),
            centerTitle: true,
            title: selectedTab == 1 
                ? Text('Ghi chú', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold))
                : Image.asset(
                    'assets/images/StudyMateRemoveBG.png',
                    height: 32,
                    fit: BoxFit.contain,
                  ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.search,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                onPressed: () {},
              ),
              if (selectedTab == 0)
                IconButton(
                  icon: Icon(
                    Icons.notifications_outlined,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  onPressed: () {},
                ),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: selectedTab,
            onTap: (i) {
              setState(() => selectedTab = i);
            },
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Colors.indigo,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
              BottomNavigationBarItem(icon: Icon(Icons.note_alt), label: 'Ghi chú'),
              BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Thống kê'),
            ],
          ),
          body: _buildBody(selectedTab, context, userName, userPhotoURL, studyStreak, totalHours.toInt(), userSnapshot),
          // MỚI: Thêm nút FAB chung cho màn hình Home để tạo nhanh
          floatingActionButton: selectedTab == 0 
            ? FloatingActionButton(
                onPressed: () => _showAddOptions(context),
                child: const Icon(Icons.add),
              )
            : null,
        );
      },
    );
  }

  Widget _buildBody(int tabIndex, BuildContext context, String userName, String? userPhotoURL, int studyStreak, int totalHours, AsyncSnapshot<DocumentSnapshot> userSnapshot) {
    switch (tabIndex) {
      case 0:
        return _buildHomeContent(context, userName, userPhotoURL, studyStreak, totalHours);
      case 1:
        return const NotesListScreen();
      case 2:
        return _buildStatistics(context, userSnapshot);
      default:
        return const SizedBox();
    }
  }

  // MỚI: Hàm hiển thị lựa chọn Thêm
  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Text(
                    'Bạn muốn tạo gì?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.style, color: Colors.indigo),
                  ),
                  title: const Text('Bộ thẻ mới (Flashcard)', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Tạo chủ đề để học từ vựng'),
                  onTap: () {
                    Navigator.pop(ctx); // Đóng menu
                    _showAddSetDialog(context); // Mở dialog tạo chủ đề
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.note_alt, color: Colors.orange),
                  ),
                  title: const Text('Ghi chú mới (Note)', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Viết ghi chú nhanh'),
                  onTap: () {
                    Navigator.pop(ctx); // Đóng menu
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const NoteEditorScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHomeContent(
    BuildContext context,
    String userName,
    String? userPhotoURL,
    int studyStreak,
    int totalHours,
  ) {
    final userInitial = (userName.isNotEmpty) ? userName[0].toUpperCase() : '?';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.green,
                backgroundImage: (userPhotoURL != null && userPhotoURL.isNotEmpty)
                    ? NetworkImage(userPhotoURL)
                    : null,
                child: (userPhotoURL != null && userPhotoURL.isNotEmpty)
                    ? null
                    : Text(
                        userInitial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Text(
                userName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  widget.isDark ? Icons.dark_mode : Icons.light_mode,
                  color: Colors.orangeAccent,
                ),
                onPressed: widget.onToggleTheme,
                tooltip: widget.isDark ? 'Chế độ tối' : 'Chế độ sáng',
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatCard(
                'Chuỗi ngày học',
                studyStreak.toString(),
                Colors.pink[100]!,
              ),
              _buildStatCard(
                'Số giờ học',
                totalHours.toString(),
                Colors.green[100]!,
              ),
            ],
          ),
          const SizedBox(height: 25),
          
          _buildSectionHeader(
            'Thư mục của tôi',
            // SỬA: Gọi _showAddOptions thay vì _showAddSetDialog trực tiếp
            onPressed: () => _showAddOptions(context),
          ),
          StreamBuilder<List<FlashcardSet>>(
            stream: _db.getFlashcardSetsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text(
                      'Lỗi tải chủ đề: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              final sets = snapshot.data ?? [];

              if (sets.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(Icons.folder_open, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'Chưa có chủ đề nào',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Nhấn nút "+" để tạo mới',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: sets.map<Widget>((set) => _buildCourseCard(
                  set,
                  '${set.cardCount} thuật ngữ',
                  Color(int.tryParse(set.color.replaceFirst('#', '0xFF')) ?? 0xFF4CAF50),
                )).toList(),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showAddSetDialog(BuildContext context) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thêm chủ đề mới'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Tên chủ đề'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Huỷ')),
          ElevatedButton(
            onPressed: () async {
              String name = nameController.text.trim();
              if (name.isEmpty) return;
              
              try {
                await _db.addFlashcardSet(name); 
                if (context.mounted) Navigator.pop(ctx);
              } catch (e) {
                 ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
              }
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

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
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onPressed}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        TextButton(
          onPressed: onPressed ?? () {},
          child: const Text(
            'Thêm',
            style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildCourseCard(FlashcardSet set, String subtitle, Color color) {
    return InkWell(
      onTap: () => _showCategoryOptions(context, set),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.5), 
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
                  Text(
                    set.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.black54),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showCategoryOptions(context, set),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryOptions(BuildContext context, FlashcardSet set) {
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
                  set.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${set.cardCount} flashcard',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
                        builder: (context) =>
                            FlashcardsScreen(set: set), 
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
                  onTap: () async {
                    Navigator.pop(ctx);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            LearningScreen(set: set), 
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
                  onTap: () async {
                    Navigator.pop(ctx);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QuizModeSelectionScreen(set: set), 
                      ),
                    );
                  },
                ),
                const Divider(height: 24),
                _buildOptionTile(
                  ctx,
                  icon: Icons.edit,
                  title: 'Đổi tên chủ đề',
                  subtitle: 'Sửa tên cho chủ đề này',
                  color: Colors.blueGrey,
                  onTap: () {
                    Navigator.pop(ctx);
                    _showEditSetDialog(context, set);
                  },
                ),
                const SizedBox(height: 12),
                _buildOptionTile(
                  ctx,
                  icon: Icons.delete,
                  title: 'Xóa chủ đề',
                  subtitle: 'Xóa chủ đề và tất cả thẻ bên trong',
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(ctx);
                    _showDeleteSetDialog(context, set);
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
  
  void _showEditSetDialog(BuildContext context, FlashcardSet set) {
    final nameController = TextEditingController(text: set.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sửa tên chủ đề'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Tên chủ đề'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Huỷ')),
          ElevatedButton(
            onPressed: () async {
              String name = nameController.text.trim();
              if (name.isEmpty) return;
              
              try {
                await _db.updateFlashcardSetTitle(set.id, name);
                if (context.mounted) Navigator.pop(ctx);
              } catch(e) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _showDeleteSetDialog(BuildContext context, FlashcardSet set) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
            'Bạn có chắc chắn muốn xóa chủ đề "${set.title}" không? Toàn bộ flashcard bên trong cũng sẽ bị xóa vĩnh viễn.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Huỷ')),
          ElevatedButton(
            onPressed: () async {
              try {
                await _db.deleteFlashcardSet(set.id);
                if (context.mounted) Navigator.pop(ctx);
              } catch (e) {
                 ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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

  Widget _buildStatistics(BuildContext context, AsyncSnapshot<DocumentSnapshot> userSnapshot) {
     if (userSnapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (userSnapshot.hasError) {
        return Center(child: Text('Lỗi tải thống kê: ${userSnapshot.error}'));
      }
      
      final data = userSnapshot.data?.data() as Map<String, dynamic>? ?? {};
      final stats = data['stats'] as Map<String, dynamic>? ?? {};

      final streak = stats['streak'] ?? 0;
      final totalHours = (stats['totalHours'] as num? ?? 0.0);
      final totalNotes = stats['totalNotes'] ?? 0;
      final totalFlashcards = stats['totalFlashcards'] ?? 0;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text(
            'Thống kê học tập',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildStatCardLarge(
                  'Chuỗi ngày học',
                  '$streak',
                  'ngày',
                  Colors.pink,
                  Icons.local_fire_department,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCardLarge(
                  'Tổng giờ học',
                  totalHours.toStringAsFixed(1),
                  'giờ',
                  Colors.green,
                  Icons.access_time,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tổng quan hoạt động',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildActivityRow('Tổng flashcard', '$totalFlashcards', Icons.style, Colors.blue),
                const SizedBox(height: 12),
                _buildActivityRow('Tổng ghi chú', '$totalNotes', Icons.note_alt, Colors.orange),
                const SizedBox(height: 12),
                _buildActivityRow('Tổng giờ học', '${totalHours.toStringAsFixed(1)} giờ', Icons.timer, Colors.green),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatCardLarge(String title, String value, String unit, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActivityRow(String title, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(fontSize: 16)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
  
  // SỬA: Hàm Drawer
  Widget _buildDrawer(
    BuildContext context,
    bool isDark,
    String userName,
    String userEmail,
    String? userPhotoURL,
  ) {
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
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  backgroundImage: (userPhotoURL != null && userPhotoURL.isNotEmpty)
                      ? NetworkImage(userPhotoURL)
                      : null,
                  child: (userPhotoURL != null && userPhotoURL.isNotEmpty)
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
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
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
          ListTile(
            leading: const Icon(Icons.home, color: Colors.indigo),
            title: const Text('Trang chủ'),
            onTap: () {
              Navigator.pop(context);
              setState(() { selectedTab = 0; });
            },
          ),
          ListTile(
            leading: const Icon(Icons.note_alt, color: Colors.indigo), // MỚI
            title: const Text('Ghi chú'),
            onTap: () {
              Navigator.pop(context);
              setState(() { selectedTab = 1; }); // Chuyển sang tab ghi chú
            },
          ),
          ListTile(
            leading: const Icon(Icons.auto_awesome, color: Colors.indigo),
            title: const Text('AI Assistant'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AIAssistantScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart, color: Colors.indigo),
            title: const Text('Thống kê'),
            onTap: () {
              Navigator.pop(context);
              setState(() { selectedTab = 2; }); // Cập nhật index thành 2
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(
                    onToggleTheme: widget.onToggleTheme,
                    isDark: widget.isDark,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.help_outline, color: Colors.indigo),
            title: const Text('Trợ giúp'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HelpScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text(
              'Đăng xuất',
              style: TextStyle(color: Colors.redAccent),
            ),
            onTap: () {
              Navigator.pop(context);
              _showLogoutDialog(context);
            },
          ),
        ],
      ),
    );
  }
  
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _auth.signOut();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Đăng xuất'),
          )
        ],
      ),
    );
  }
}