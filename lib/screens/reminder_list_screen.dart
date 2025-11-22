import 'package:flutter/material.dart';
import '../models/study_reminder.dart';
import '../services/firestore_service.dart';
import 'add_edit_reminder_screen.dart';

class ReminderListScreen extends StatelessWidget {
  const ReminderListScreen({super.key});

  // 🛠️ Hàm hiển thị hộp thoại xác nhận xóa (Dùng chung cho cả nút bấm và vuốt)
  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text("Xóa nhắc nhở?"),
          ],
        ),
        content: const Text("Hành động này sẽ xóa vĩnh viễn nhắc nhở và hủy lịch thông báo của nó."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Xóa"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final FirestoreService db = FirestoreService();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Danh sách nhắc nhở',
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
      ),
      body: StreamBuilder<List<StudyReminder>>(
        stream: db.getRemindersStream(),
        builder: (context, snapshot) {
          // 1. Đang tải
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Lỗi
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  const Text("Lỗi tải dữ liệu!"),
                  Text("Chi tiết: ${snapshot.error}", style: const TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final reminders = snapshot.data ?? [];

          // 3. Danh sách trống
          if (reminders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có nhắc nhở nào',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddEditReminderScreen()),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text("Thêm ngay"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                    ),
                  )
                ],
              ),
            );
          }

          // 4. Hiển thị danh sách
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reminders.length,
            itemBuilder: (context, index) {
              final reminder = reminders[index];
              
              // Vẫn giữ tính năng vuốt để xóa (Dismissible)
              return Dismissible(
                key: Key(reminder.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red[400],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_forever, color: Colors.white, size: 32),
                ),
                confirmDismiss: (direction) => _showDeleteConfirmation(context),
                onDismissed: (_) {
                  db.deleteReminder(reminder);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã xóa nhắc nhở')),
                  );
                },
                child: Card(
                  elevation: 2,
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AddEditReminderScreen(reminder: reminder)),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          // CỘT 1: Thông tin (Giờ, Tên, Ngày lặp)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      reminder.timeString,
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        color: reminder.isEnabled
                                            ? (isDark ? Colors.white : Colors.indigo)
                                            : Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      reminder.hour < 12 ? "AM" : "PM",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  reminder.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: isDark ? Colors.white70 : Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.black26 : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.calendar_today, size: 12, color: Colors.grey[500]),
                                      const SizedBox(width: 6),
                                      Text(
                                        reminder.daysString,
                                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // CỘT 2: Các nút thao tác (Bật/Tắt & Xóa)
                          Column(
                            children: [
                              // Nút Bật/Tắt
                              Transform.scale(
                                scale: 0.85,
                                child: Switch(
                                  value: reminder.isEnabled,
                                  activeColor: Colors.indigo,
                                  onChanged: (val) => db.toggleReminder(reminder, val),
                                ),
                              ),
                              
                              // 🔥 NÚT XÓA MỚI THÊM
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                tooltip: 'Xóa nhắc nhở này',
                                onPressed: () async {
                                  final confirm = await _showDeleteConfirmation(context);
                                  if (confirm == true) {
                                    await db.deleteReminder(reminder);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Đã xóa nhắc nhở')),
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEditReminderScreen()),
          );
        },
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}