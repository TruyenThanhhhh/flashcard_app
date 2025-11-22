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
import 'note_editor_screen.dart';
import 'notification_screen.dart';
import 'statistics_screen.dart'; // Import màn hình thống kê riêng

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
    
    // Stream chính để lấy thông tin User (Tên, Avatar, Stats)
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
            // Thay đổi tiêu đề dựa trên tab đang chọn
            title: _buildAppBarTitle(selectedTab, isDark),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.search,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                onPressed: () {},
              ),
              // Nút thông báo (Chỉ hiện ở tab Trang chủ để đỡ rối)
              if (selectedTab == 0)
                StreamBuilder<int>(
                  stream: _db.getUnreadNotificationsCount(),
                  builder: (context, snapshot) {
                    int unreadCount = snapshot.data ?? 0;
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.notifications_outlined,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const NotificationScreen()),
                            );
                          },
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                '$unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                      ],
                    );
                  },
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
            unselectedItemColor: Colors.grey,
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
              BottomNavigationBarItem(icon: Icon(Icons.note_alt), label: 'Ghi chú'),
              BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Thống kê'),
            ],
          ),
          
          // Body thay đổi theo Tab
          body: _buildBody(selectedTab, context, userName, userPhotoURL, studyStreak, totalHours.toInt(), userSnapshot),
          
          // Nút FAB chỉ hiện ở trang chủ (Trang Ghi chú có FAB riêng bên trong)
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

  Widget _buildAppBarTitle(int tabIndex, bool isDark) {
    if (tabIndex == 1) {
      return Text('Ghi chú', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold));
    } else if (tabIndex == 2) {
      return Text('Thống kê', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold));
    }
    return Image.asset(
      'assets/images/StudyMateRemoveBG.png',
      height: 32,
      fit: BoxFit.contain,
    );
  }

  Widget _buildBody(int tabIndex, BuildContext context, String userName, String? userPhotoURL, int studyStreak, int totalHours, AsyncSnapshot<DocumentSnapshot> userSnapshot) {
    switch (tabIndex) {
      case 0:
        return _buildHomeContent(context, userName, userPhotoURL, studyStreak, totalHours);
      case 1:
        return const NotesListScreen(); // Màn hình ghi chú
      case 2:
        // Lấy dữ liệu stats từ snapshot và truyền vào màn hình thống kê riêng
        final stats = (userSnapshot.data?.data() as Map<String, dynamic>?)?['stats'] as Map<String, dynamic>? ?? {};
        return StatisticsScreen(userStats: stats); 
      default:
        return const SizedBox();
    }
  }

  // --- Bottom Sheet chọn tạo mới ---
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
                    Navigator.pop(ctx);
                    _showAddSetDialog(context);
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
                    Navigator.pop(ctx);
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

  // --- Nội dung Trang chủ (Flashcards) ---
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
          // Header User Info
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
              
              // 🔥 FIX LỖI TRÀN TÊN: Dùng Expanded + TextOverflow
              Expanded(
                child: Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1, // Chỉ hiện 1 dòng
                  overflow: TextOverflow.ellipsis, // Hiện ... nếu quá dài
                ),
              ),
              
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

          // Thẻ thống kê nhanh (Mini stats)
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
            onPressed: () => _showAddOptions(context),
          ),

          // Danh sách Bộ thẻ
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
                return Center(child: Text('Lỗi: ${snapshot.error}'));
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

  // --- Các Widget & Hàm phụ trợ ---

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
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
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
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
                Text(set.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('${set.cardCount} flashcard', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                const SizedBox(height: 24),
                
                _buildOptionTile(ctx, Icons.style, 'Xem Flashcard', 'Xem và quản lý tất cả flashcard', Colors.indigo, () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => FlashcardsScreen(set: set)));
                }),
                const SizedBox(height: 12),
                _buildOptionTile(ctx, Icons.school, 'Chế độ học', 'Học và ghi nhớ flashcard', Colors.green, () async {
                    Navigator.pop(ctx);
                    await Navigator.push(context, MaterialPageRoute(builder: (context) => LearningScreen(set: set)));
                }),
                const SizedBox(height: 12),
                _buildOptionTile(ctx, Icons.quiz, 'Làm Quiz', 'Kiểm tra kiến thức của bạn', Colors.orange, () async {
                    Navigator.pop(ctx);
                    await Navigator.push(context, MaterialPageRoute(builder: (context) => QuizModeSelectionScreen(set: set)));
                }),
                const Divider(height: 24),
                _buildOptionTile(ctx, Icons.edit, 'Đổi tên chủ đề', 'Sửa tên cho chủ đề này', Colors.blueGrey, () {
                    Navigator.pop(ctx);
                    _showEditSetDialog(context, set);
                }),
                const SizedBox(height: 12),
                _buildOptionTile(ctx, Icons.delete, 'Xóa chủ đề', 'Xóa chủ đề và tất cả thẻ bên trong', Colors.red, () {
                    Navigator.pop(ctx);
                    _showDeleteSetDialog(context, set);
                }),
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
        content: TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Tên chủ đề'), autofocus: true),
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
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
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
        content: Text('Bạn có chắc chắn muốn xóa chủ đề "${set.title}" không? Toàn bộ flashcard bên trong cũng sẽ bị xóa vĩnh viễn.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Huỷ')),
          ElevatedButton(
            onPressed: () async {
              try {
                await _db.deleteFlashcardSet(set.id);
                if (context.mounted) Navigator.pop(ctx);
              } catch (e) {
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile(BuildContext context, IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
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
              decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 18),
          ],
        ),
      ),
    );
  }
  
  // Drawer
  Widget _buildDrawer(BuildContext context, bool isDark, String userName, String userEmail, String? userPhotoURL) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.indigo, Colors.indigo.shade700])),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  backgroundImage: (userPhotoURL != null && userPhotoURL.isNotEmpty) ? NetworkImage(userPhotoURL) : null,
                  child: (userPhotoURL != null && userPhotoURL.isNotEmpty) ? null : Text((userName.isNotEmpty) ? userName[0].toUpperCase() : '?', style: const TextStyle(color: Colors.indigo, fontSize: 32, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                Text(userName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(userEmail, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home, color: Colors.indigo),
            title: const Text('Trang chủ'),
            onTap: () { Navigator.pop(context); setState(() { selectedTab = 0; }); },
          ),
          ListTile(
            leading: const Icon(Icons.note_alt, color: Colors.indigo),
            title: const Text('Ghi chú'),
            onTap: () { Navigator.pop(context); setState(() { selectedTab = 1; }); },
          ),
          ListTile(
            leading: const Icon(Icons.auto_awesome, color: Colors.indigo),
            title: const Text('AI Assistant'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AIAssistantScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart, color: Colors.indigo),
            title: const Text('Thống kê'),
            onTap: () { Navigator.pop(context); setState(() { selectedTab = 2; }); },
          ),
          const Divider(),
          ListTile(
            leading: Icon(isDark ? Icons.light_mode : Icons.dark_mode, color: Colors.indigo),
            title: Text(isDark ? 'Chế độ sáng' : 'Chế độ tối'),
            onTap: () {
              Navigator.pop(context);
              if (widget.onToggleTheme != null) widget.onToggleTheme!();
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.indigo),
            title: const Text('Cài đặt'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsScreen(onToggleTheme: widget.onToggleTheme, isDark: widget.isDark)));
            },
          ),
          ListTile(
            leading: const Icon(Icons.help_outline, color: Colors.indigo),
            title: const Text('Trợ giúp'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpScreen()));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Đăng xuất', style: TextStyle(color: Colors.redAccent)),
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Huỷ')),
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