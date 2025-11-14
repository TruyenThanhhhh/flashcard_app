// lib/screens/quiz_mode_selection_screen.dart

import 'package:flutter/material.dart';
// SỬA: Dùng model mới
import '../models/flashcard_set.dart'; 
import 'quiz_screen.dart';

enum QuizMode {
  multipleChoice,
  fillInTheBlank,
}

class QuizModeSelectionScreen extends StatelessWidget {
  // SỬA: Nhận vào FlashcardSet
  final FlashcardSet set;
  const QuizModeSelectionScreen({super.key, required this.set});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? Color(0xFF0F172A) : Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        title: Text(
          'Chọn chế độ Quiz',
          style: TextStyle(
            color: isDark ? Colors.white : Color(0xFF1E293B),
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Color(0xFF1E293B),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Icon(Icons.quiz, color: Colors.white, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      set.title, // SỬA: Dùng title
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${set.cardCount} câu hỏi', // SỬA: Dùng cardCount
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Instructions
              Text(
                'Chọn chế độ quiz bạn muốn:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 24),
              
              // Multiple Choice Option
              _buildModeCard(
                context,
                isDark,
                mode: QuizMode.multipleChoice,
                icon: Icons.check_circle_outline,
                title: 'Trắc nghiệm',
                subtitle: 'Chọn đáp án đúng từ 4 lựa chọn',
                color: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuizScreen(
                        set: set, // SỬA: Truyền 'set'
                        mode: QuizMode.multipleChoice,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              
              // Fill in the Blank Option
              _buildModeCard(
                context,
                isDark,
                mode: QuizMode.fillInTheBlank,
                icon: Icons.edit,
                title: 'Điền đáp án',
                subtitle: 'Gõ câu trả lời của bạn',
                color: Colors.orange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuizScreen(
                        set: set, // SỬA: Truyền 'set'
                        mode: QuizMode.fillInTheBlank,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard(
    BuildContext context,
    bool isDark, {
    required QuizMode mode,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    // ... (Toàn bộ UI của hàm này giữ nguyên, không cần sửa) ...
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}