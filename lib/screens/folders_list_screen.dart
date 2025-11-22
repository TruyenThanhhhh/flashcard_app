import 'package:flutter/material.dart';
import '../models/flashcard_set.dart';
import '../services/firestore_service.dart';
import 'flashcards_screen.dart';
import 'learning_screen.dart';
import 'quiz_mode_selection_screen.dart';

class FoldersListScreen extends StatefulWidget {
  const FoldersListScreen({super.key});

  @override
  State<FoldersListScreen> createState() => _FoldersListScreenState();
}

class _FoldersListScreenState extends State<FoldersListScreen> {
  final FirestoreService _db = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.grey[100],
      appBar: AppBar(
        title: Text('Thư mục của tôi', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
      ),
      body: StreamBuilder<List<FlashcardSet>>(
        stream: _db.getFlashcardSetsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          final sets = snapshot.data ?? [];

          if (sets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có chủ đề nào',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sets.length,
            itemBuilder: (context, index) {
              final set = sets[index];
              return _buildFolderCard(context, set, isDark);
            },
          );
        },
      ),
    );
  }

  Widget _buildFolderCard(BuildContext context, FlashcardSet set, bool isDark) {
    return InkWell(
      onTap: () => _showFolderOptions(context, set),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Color(int.tryParse(set.color.replaceFirst('#', '0xFF')) ?? 0xFF4CAF50).withOpacity(0.5),
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
                  Text(
                    '${set.cardCount} flashcard',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showFolderOptions(context, set),
            ),
          ],
        ),
      ),
    );
  }

  void _showFolderOptions(BuildContext context, FlashcardSet set) {
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
                _buildOptionTile(ctx, Icons.edit, 'Đổi tên', 'Sửa tên cho chủ đề này', Colors.blueGrey, () {
                    Navigator.pop(ctx);
                    _showEditSetDialog(context, set);
                }),
                const SizedBox(height: 12),
                _buildOptionTile(ctx, Icons.lock_outline, 'Quyền riêng tư', 'Thay đổi quyền riêng tư của bài học', Colors.purple, () {
                    Navigator.pop(ctx);
                    _showPrivacyDialog(context, set);
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
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                }
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
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context, FlashcardSet set) {
    bool isPublic = set.isPublic;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Quyền riêng tư'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<bool>(
                  title: const Text('Riêng tư'),
                  subtitle: const Text('Chỉ bạn có thể xem bài học này'),
                  value: false,
                  groupValue: isPublic,
                  onChanged: (value) {
                    setState(() {
                      isPublic = value ?? false;
                    });
                  },
                ),
                RadioListTile<bool>(
                  title: const Text('Công khai'),
                  subtitle: const Text('Mọi người có thể xem và học bài học này'),
                  value: true,
                  groupValue: isPublic,
                  onChanged: (value) {
                    setState(() {
                      isPublic = value ?? true;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Huỷ')),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await _db.updateFlashcardSetPrivacy(set.id, isPublic);
                    if (context.mounted) Navigator.pop(ctx);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                    }
                  }
                },
                child: const Text('Lưu'),
              ),
            ],
          );
        },
      ),
    );
  }
}

