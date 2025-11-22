import 'package:flutter/material.dart';
import '../models/study_reminder.dart';
import '../services/firestore_service.dart';
import 'add_edit_reminder_screen.dart'; // Màn hình tạo mới sẽ làm ở bước sau

class ReminderListScreen extends StatelessWidget {
  const ReminderListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService db = FirestoreService();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Danh sách nhắc nhở', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
      ),
      body: StreamBuilder<List<StudyReminder>>(
        stream: db.getRemindersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final reminders = snapshot.data ?? [];

          if (reminders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.alarm_off, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('Chưa có nhắc nhở nào', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reminders.length,
            itemBuilder: (context, index) {
              final reminder = reminders[index];
              return Dismissible(
                key: Key(reminder.id),
                background: Container(color: Colors.red, child: const Icon(Icons.delete, color: Colors.white)),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => db.deleteReminder(reminder),
                child: Card(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(
                      reminder.timeString,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(reminder.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(reminder.daysString, style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                    trailing: Switch(
                      value: reminder.isEnabled,
                      activeColor: Colors.indigo,
                      onChanged: (val) => db.toggleReminder(reminder, val),
                    ),
                    onTap: () {
                       Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AddEditReminderScreen(reminder: reminder)),
                      );
                    },
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
        child: const Icon(Icons.add),
      ),
    );
  }
}