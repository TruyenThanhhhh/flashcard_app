import 'package:flutter/material.dart';
import '../models/category.dart';
import '../screens/flashcards_screen.dart';
import '../screens/learning_screen.dart';
import '../screens/quiz_screen.dart';
import '../data/demo_data.dart';
import '../screens/ai_assistant_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onToggleTheme;
  final bool isDark;
  const HomeScreen({super.key, this.onToggleTheme, this.isDark = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late List<Category> categories;
  int selectedTab = 0;
  late AnimationController _animationController;
  
  final List<Map<String,dynamic>> topicIcons = [
    {'icon': Icons.auto_stories, 'color': Color(0xFF6366F1), 'gradient': [Color(0xFF6366F1), Color(0xFF8B5CF6)]},
    {'icon': Icons.pets, 'color': Color(0xFF10B981), 'gradient': [Color(0xFF10B981), Color(0xFF059669)]},
    {'icon': Icons.chat_bubble_outline, 'color': Color(0xFFF59E0B), 'gradient': [Color(0xFFF59E0B), Color(0xFFEF4444)]},
  ];

  @override
  void initState() {
    super.initState();
    categories = demoCategories;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return Scaffold(
      backgroundColor: isDark ? Color(0xFF0F172A) : Color(0xFFF8FAFC),
      body: selectedTab == 0 ? _buildHomeTab(isDark) : _buildStatsTab(isDark),
      bottomNavigationBar: _buildBottomNav(isDark),
    );
  }

  Widget _buildHomeTab(bool isDark) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildAppBar(isDark),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return FadeTransition(
                  opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _animationController,
                      curve: Interval(
                        0.1 * index,
                        0.3 + (0.1 * index),
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                  ),
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: _animationController,
                        curve: Interval(
                          0.1 * index,
                          0.3 + (0.1 * index),
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                    ),
                    child: _buildCategoryCard(categories[index], index, isDark),
                  ),
                );
              },
              childCount: categories.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(bool isDark) {
  return SliverAppBar(
    expandedHeight: 180,
    floating: false,
    pinned: true,
    backgroundColor: isDark ? Color(0xFF1E293B) : Colors.white,
    elevation: 0,
    flexibleSpace: FlexibleSpaceBar(
      background: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
              ? [Color(0xFF1E293B), Color(0xFF334155)]
              : [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(Icons.school, color: Colors.white, size: 32),
                    ),
                    const Spacer(),
                    // ← THÊM NÚT AI ASSISTANT TẠI ĐÂY
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.auto_awesome, color: Colors.white),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AIAssistantScreen(),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        isDark ? Icons.light_mode : Icons.dark_mode,
                        color: Colors.white,
                      ),
                      onPressed: widget.onToggleTheme,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Học từ vựng',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  '${categories.length} chủ đề · ${categories.fold(0, (sum, c) => sum + c.cards.length)} flashcards',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

  Widget _buildCategoryCard(Category category, int index, bool isDark) {
    final iconData = topicIcons[index % topicIcons.length];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => LearningScreen(category: category)),
            );
          },
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            decoration: BoxDecoration(
              color: isDark ? Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: isDark 
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: iconData['gradient'],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: iconData['color'].withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(iconData['icon'], color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${category.cards.length} thẻ',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'learn') {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => LearningScreen(category: category),
                        ));
                      } else if (value == 'manage') {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => FlashcardsScreen(category: category),
                        ));
                      } else if (value == 'quiz') {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => QuizScreen(category: category),
                        ));
                      }
                    },
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    itemBuilder: (ctx) => [
                      PopupMenuItem<String>(
                        value: 'learn',
                        child: Row(
                          children: const [
                            Icon(Icons.school_outlined, size: 20),
                            SizedBox(width: 12),
                            Text('Chế độ học'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'quiz',
                        child: Row(
                          children: const [
                            Icon(Icons.quiz_outlined, size: 20),
                            SizedBox(width: 12),
                            Text('Làm quiz'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'manage',
                        child: Row(
                          children: const [
                            Icon(Icons.edit_outlined, size: 20),
                            SizedBox(width: 12),
                            Text('Quản lý thẻ'),
                          ],
                        ),
                      ),
                    ],
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark 
                          ? Colors.white.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.more_horiz,
                        color: isDark ? Colors.white : Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsTab(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? Color(0xFF1E293B) : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.bar_chart_rounded,
              size: 64,
              color: Color(0xFF6366F1),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Thống kê',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tính năng đang được phát triển',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1E293B) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_rounded,
                label: 'Trang chủ',
                isSelected: selectedTab == 0,
                onTap: () => setState(() => selectedTab = 0),
                isDark: isDark,
              ),
              _buildNavItem(
                icon: Icons.bar_chart_rounded,
                label: 'Thống kê',
                isSelected: selectedTab == 1,
                onTap: () => setState(() => selectedTab = 1),
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
            ? (isDark ? Color(0xFF6366F1).withOpacity(0.2) : Color(0xFF6366F1).withOpacity(0.1))
            : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected 
                ? Color(0xFF6366F1)
                : (isDark ? Colors.grey[500] : Colors.grey[600]),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Color(0xFF6366F1),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}