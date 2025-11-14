import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? Color(0xFF0F172A) : Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        title: const Text(
          'Trợ giúp',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
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
                  Icon(Icons.help_outline, color: Colors.white, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Chào mừng đến với StudyMate!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Chúng tôi ở đây để giúp bạn',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // FAQ Section
            _buildSectionTitle('Câu hỏi thường gặp', isDark),
            const SizedBox(height: 12),
            _buildFAQCard(
              context,
              isDark,
              question: 'Làm thế nào để tạo flashcard mới?',
              answer: 'Chọn một chủ đề từ trang chủ, sau đó nhấn "Xem Flashcard" và sử dụng nút "+" để thêm flashcard mới.',
            ),
            const SizedBox(height: 12),
            _buildFAQCard(
              context,
              isDark,
              question: 'Làm thế nào để học flashcard?',
              answer: 'Chọn chủ đề bạn muốn học, nhấn "Chế độ học" và bắt đầu lật các thẻ để học từ vựng.',
            ),
            const SizedBox(height: 12),
            _buildFAQCard(
              context,
              isDark,
              question: 'Quiz hoạt động như thế nào?',
              answer: 'Chọn chủ đề và nhấn "Làm Quiz". Bạn sẽ được hỏi về nghĩa của các từ và nhận điểm sau khi hoàn thành.',
            ),
            const SizedBox(height: 12),
            _buildFAQCard(
              context,
              isDark,
              question: 'Làm thế nào để xem thống kê học tập?',
              answer: 'Nhấn vào tab "Thống kê" ở thanh điều hướng dưới cùng để xem giờ học, chuỗi ngày học và lịch sử học tập.',
            ),
            const SizedBox(height: 24),
            
            // Features Section
            _buildSectionTitle('Tính năng chính', isDark),
            const SizedBox(height: 12),
            _buildFeatureCard(
              context,
              isDark,
              icon: Icons.style,
              title: 'Flashcard',
              description: 'Tạo và quản lý flashcard của bạn một cách dễ dàng',
            ),
            const SizedBox(height: 12),
            _buildFeatureCard(
              context,
              isDark,
              icon: Icons.school,
              title: 'Chế độ học',
              description: 'Học từ vựng bằng cách lật thẻ và ghi nhớ',
            ),
            const SizedBox(height: 12),
            _buildFeatureCard(
              context,
              isDark,
              icon: Icons.quiz,
              title: 'Quiz',
              description: 'Kiểm tra kiến thức của bạn với các câu hỏi quiz',
            ),
            const SizedBox(height: 12),
            _buildFeatureCard(
              context,
              isDark,
              icon: Icons.auto_awesome,
              title: 'AI Assistant',
              description: 'Nhận trợ giúp từ AI về ngữ pháp và từ vựng',
            ),
            const SizedBox(height: 24),
            
            // Contact Section
            _buildSectionTitle('Liên hệ', isDark),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildContactItem(
                    context,
                    isDark,
                    icon: Icons.email,
                    title: 'Email hỗ trợ',
                    value: 'support@studymate.com',
                  ),
                  const Divider(height: 32),
                  _buildContactItem(
                    context,
                    isDark,
                    icon: Icons.phone,
                    title: 'Hotline',
                    value: '1900-xxxx',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : Color(0xFF1E293B),
      ),
    );
  }

  Widget _buildFAQCard(
    BuildContext context,
    bool isDark, {
    required String question,
    required String answer,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.help_outline,
                color: Colors.indigo,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  question,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Text(
              answer,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[700],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    bool isDark, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.indigo, size: 24),
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
                    color: isDark ? Colors.white : Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(
    BuildContext context,
    bool isDark, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.indigo, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

