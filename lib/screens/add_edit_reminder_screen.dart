import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/study_reminder.dart';
import '../services/firestore_service.dart';

class AddEditReminderScreen extends StatefulWidget {
  final StudyReminder? reminder;
  const AddEditReminderScreen({super.key, this.reminder});

  @override
  State<AddEditReminderScreen> createState() => _AddEditReminderScreenState();
}

class _AddEditReminderScreenState extends State<AddEditReminderScreen> {
  final _titleController = TextEditingController(text: "Đến giờ học rồi! 📚");
  late Duration _selectedTime;
  List<int> _selectedDays = [1, 2, 3, 4, 5, 6, 7];

  @override
  void initState() {
    super.initState();
    if (widget.reminder != null) {
      _titleController.text = widget.reminder!.title;
      _selectedTime = Duration(hours: widget.reminder!.hour, minutes: widget.reminder!.minute);
      _selectedDays = List.from(widget.reminder!.weekDays);
    } else {
      _selectedTime = const Duration(hours: 20, minutes: 0);
    }
  }

  void _toggleDay(int id) {
    setState(() {
      if (_selectedDays.contains(id)) {
        if (_selectedDays.length > 1) _selectedDays.remove(id);
      } else {
        _selectedDays.add(id);
      }
      _selectedDays.sort();
    });
  }

  Future<void> _save() async {
    final db = FirestoreService();
    final hour = _selectedTime.inHours;
    final minute = _selectedTime.inMinutes % 60;

    if (widget.reminder == null) {
      await db.addReminder(_titleController.text, hour, minute, _selectedDays);
    } else {
      final updatedReminder = StudyReminder(
        id: widget.reminder!.id,
        title: _titleController.text,
        hour: hour,
        minute: minute,
        weekDays: _selectedDays,
        isEnabled: true, // Sửa xong tự động bật lại
        notificationId: widget.reminder!.notificationId,
      );
      await db.updateReminder(updatedReminder);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final weekDays = [
      {'id': 1, 'label': 'T2'}, {'id': 2, 'label': 'T3'}, {'id': 3, 'label': 'T4'},
      {'id': 4, 'label': 'T5'}, {'id': 5, 'label': 'T6'}, {'id': 6, 'label': 'T7'},
      {'id': 7, 'label': 'CN'}
    ];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(widget.reminder == null ? 'Thêm nhắc nhở' : 'Sửa nhắc nhở', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        actions: [TextButton(onPressed: _save, child: const Text('Lưu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             // Tên
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: "Tên nhắc nhở",
                filled: true,
                fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            ),
            const SizedBox(height: 24),

            // Giờ
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: CupertinoTheme(
                data: CupertinoThemeData(brightness: isDark ? Brightness.dark : Brightness.light),
                child: CupertinoTimerPicker(
                  mode: CupertinoTimerPickerMode.hm,
                  initialTimerDuration: _selectedTime,
                  onTimerDurationChanged: (val) => setState(() => _selectedTime = val),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Ngày
            const Text("Lặp lại", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: weekDays.map((day) {
                final isSelected = _selectedDays.contains(day['id']);
                return FilterChip(
                  label: Text(day['label'] as String),
                  selected: isSelected,
                  onSelected: (_) => _toggleDay(day['id'] as int),
                  selectedColor: Colors.indigo,
                  labelStyle: TextStyle(color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87)),
                  backgroundColor: isDark ? const Color(0xFF334155) : Colors.grey[200],
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}