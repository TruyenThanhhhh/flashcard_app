import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/category.dart';
import '../models/flashcard.dart';
import '../services/firestore_service.dart'; // SỬA: Dùng FirestoreService
import '../services/auth_service.dart'; // SỬA: Dùng AuthService

class LearningScreen extends StatefulWidget {
  final Category category;
  const LearningScreen({super.key, required this.category});

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> with TickerProviderStateMixin {
  late List<Flashcard> cards;
  late List<bool> rememberedCards;
  int index = 0;
  bool showAnswer = false;
  bool showTip = true;
  DateTime? _sessionStartTime;
  
  // SỬA: Khởi tạo các service
  final FirestoreService _db = FirestoreService();
  final AuthService _auth = AuthService();
  
  late AnimationController _flipController;
  late AnimationController _progressController;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _sessionStartTime = DateTime.now();
    cards = [...widget.category.cards];
    rememberedCards = List.filled(cards.length, false);
    
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOutCubic),
    );
    
    _progressController.forward();
  }

  @override
  void dispose() {
    _flipController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _toggleCard() {
    setState(() {
      showAnswer = !showAnswer;
      showTip = false;
    });
    
    if (showAnswer) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
  }

  void markAsRemembered(bool remembered) {
    setState(() {
      rememberedCards[index] = remembered;
      
      if (index < cards.length - 1) {
        index++;
        showAnswer = false;
        _flipController.reset();
        _progressController.reset();
        _progressController.forward();
      } else {
        _showCompletionDialog();
      }
    });
  }

  // SỬA: Hàm này để gọi service
  Future<void> _showCompletionDialog() async {
    final remembered = rememberedCards.where((e) => e).length;
    final total = cards.length;
    final percentage = (total == 0) ? 0 : (remembered / total * 100).toInt();
    
    // Record the learning session
    if (_sessionStartTime != null) {
      final duration = DateTime.now().difference(_sessionStartTime!);
      // Không cần check _auth.currentUser nữa vì service đã làm
      try {
        await _db.recordLearningSession(
          categoryId: widget.category.id,
          categoryName: widget.category.name,
          duration: duration,
          cardsLearned: remembered,
        );
      } catch (e) {
        print("Lỗi khi lưu buổi học: $e");
        // Có thể hiện SnackBar lỗi
      }
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.emoji_events, color: Colors.white, size: 48),
              ),
              const SizedBox(height: 24),
              Text(
                'Hoàn thành!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Bạn đã học xong ${widget.category.name}',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text(
                      '$percentage%',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                    Text(
                      'Đã nhớ $remembered/$total thẻ',
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context)..pop()..pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6366F1),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Hoàn tất',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.category.name)),
        body: const Center(child: Text('Chủ đề chưa có flashcard.')),
      );
    }
    
    final card = cards[index];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? Color(0xFF0F172A) : Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            _buildProgressBar(isDark),
            if (showTip) _buildTipCard(),
            Expanded(
              child: Center(
                child: _buildFlashcard(card, isDark),
              ),
            ),
            _buildActionButtons(isDark),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Color(0xFF1E293B)),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.category.name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Color(0xFF1E293B),
                  ),
                ),
                Text(
                  'Chế độ học',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${index + 1}/${cards.length}',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: (index + 1) / cards.length,
                    backgroundColor: isDark ? Color(0xFF1E293B) : Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Color(0xFF10B981), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${rememberedCards.where((e) => e).length}',
                      style: TextStyle(
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        offset: Offset.zero,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Color(0xFFD97706)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Chạm vào thẻ để xem nghĩa',
                  style: TextStyle(
                    color: Color(0xFFD97706),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: Color(0xFFD97706), size: 20),
                onPressed: () => setState(() => showTip = false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFlashcard(Flashcard card, bool isDark) {
    return GestureDetector(
      onTap: _toggleCard,
      child: AnimatedBuilder(
        animation: _flipAnimation,
        builder: (context, child) {
          final angle = _flipAnimation.value * math.pi;
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle);
          
          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: angle <= math.pi / 2
                ? _buildCardFront(card.english, isDark)
                : Transform(
                    transform: Matrix4.identity()..rotateY(math.pi),
                    alignment: Alignment.center,
                    child: _buildCardBack(card.vietnamese, isDark),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildCardFront(String text, bool isDark) {
    return Container(
      width: 320,
      height: 420,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF6366F1).withOpacity(0.4),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.translate,
            color: Colors.white.withOpacity(0.3),
            size: 48,
          ),
          const SizedBox(height: 24),
          Text(
            text,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.touch_app, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Chạm để lật',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack(String text, bool isDark) {
    return Container(
      width: 320,
      height: 420,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF10B981), Color(0xFF059669)],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF10B981).withOpacity(0.4),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.verified,
            color: Colors.white.withOpacity(0.3),
            size: 48,
          ),
          const SizedBox(height: 24),
          Text(
            text,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Nghĩa tiếng Việt',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: showAnswer ? null : _toggleCard,
                  icon: Icon(Icons.flip),
                  label: Text('Xoay thẻ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Color(0xFF334155) : Colors.white,
                    foregroundColor: isDark ? Colors.white : Color(0xFF64748B),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                    side: BorderSide(
                      color: isDark ? Color(0xFF475569) : Color(0xFFE2E8F0),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => markAsRemembered(false),
                  icon: Icon(Icons.close_rounded),
                  label: Text('Chưa nhớ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => markAsRemembered(true),
                  icon: Icon(Icons.check_rounded),
                  label: Text('Đã nhớ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}