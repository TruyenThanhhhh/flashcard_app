// lib/screens/learning_screen.dart

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/flashcard_set.dart';
import '../models/flashcard.dart';
import '../services/firestore_service.dart';

class LearningScreen extends StatefulWidget {
  final FlashcardSet set;
  const LearningScreen({super.key, required this.set});

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> with TickerProviderStateMixin {
  final FirestoreService _db = FirestoreService();
  
  late Future<List<Flashcard>> _cardsFuture;

  // Dữ liệu cho phiên học hiện tại
  List<Flashcard> cards = [];
  late List<bool> rememberedCards;
  
  int index = 0;
  bool showAnswer = false;
  // ĐÃ XÓA: bool showTip = true;
  
  DateTime? _sessionStartTime;
  bool _isSessionInitialized = false;

  late AnimationController _flipController;
  late AnimationController _progressController;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _sessionStartTime = DateTime.now();
    
    _cardsFuture = _db.getFlashcardsOnce(
      widget.set.id,
      userId: widget.set.isPublic ? widget.set.userId : null,
    );

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

  // Hàm khởi động lại phiên học với danh sách thẻ cụ thể
  void _restartSession(List<Flashcard> newCards) {
    if (newCards.isEmpty) return;
    
    setState(() {
      cards = newCards;
      rememberedCards = List.filled(cards.length, false);
      index = 0;
      showAnswer = false;
      _flipController.reset();
      _progressController.reset();
      _progressController.forward();
      _sessionStartTime = DateTime.now();
    });
    Navigator.of(context).pop(); // Đóng dialog
  }

  Future<void> _showCompletionDialog() async {
    final rememberedCount = rememberedCards.where((e) => e).length;
    final total = cards.length;
    final percentage = (total == 0) ? 0 : (rememberedCount / total * 100).toInt();
    
    // Tách danh sách để dùng cho các nút chức năng
    final forgottenList = <Flashcard>[];
    final rememberedList = <Flashcard>[];
    
    for (int i = 0; i < cards.length; i++) {
      if (rememberedCards[i]) {
        rememberedList.add(cards[i]);
      } else {
        forgottenList.add(cards[i]);
      }
    }

    // Lưu thống kê vào Firebase
    if (_sessionStartTime != null) {
      final duration = DateTime.now().difference(_sessionStartTime!);
      try {
        await _db.recordLearningSession(
          categoryId: widget.set.id,
          categoryName: widget.set.title,
          duration: duration,
          cardsLearned: rememberedCount,
        );
      } catch (e) {
        debugPrint("Lỗi khi lưu buổi học: $e");
      }
    }
    
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Cup
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.emoji_events, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 16),
              
              // Tiêu đề & Kết quả
              const Text(
                'Hoàn thành!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Bạn đã nhớ $rememberedCount/$total thẻ ($percentage%)',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              // --- CÁC NÚT CHỨC NĂNG MỚI ---
              
              // 1. Nút Ôn tập từ chưa nhớ (chỉ hiện nếu có từ chưa nhớ)
              if (forgottenList.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _restartSession(forgottenList),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Ôn ${forgottenList.length} từ chưa nhớ', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),

              // 2. Nút Ôn tập từ đã nhớ (chỉ hiện nếu có từ đã nhớ)
              if (rememberedList.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _restartSession(rememberedList),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF10B981)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Ôn ${rememberedList.length} từ đã nhớ', style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),

              // 3. Nút Học lại tất cả
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _restartSession(cards), // cards lúc này là danh sách đầy đủ của phiên vừa rồi
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Học lại tất cả', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),

              // 4. Nút Kết thúc (Thoát)
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Đóng dialog
                    Navigator.of(context).pop(); // Thoát màn hình học
                  },
                  child: Text('Kết thúc', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
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
    return FutureBuilder<List<Flashcard>>(
      future: _cardsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: Text(widget.set.title)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: Text(widget.set.title)),
            body: Center(child: Text('Lỗi tải thẻ: ${snapshot.error}')),
          );
        }

        final loadedCards = snapshot.data ?? [];
        if (loadedCards.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: Text(widget.set.title)),
            body: const Center(child: Text('Chủ đề chưa có flashcard.')),
          );
        }

        if (!_isSessionInitialized) {
          cards = loadedCards;
          rememberedCards = List.filled(cards.length, false);
          _progressController.forward();
          _isSessionInitialized = true;
        }

        if (cards.isEmpty) {
           return Scaffold(
            appBar: AppBar(title: Text(widget.set.title)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        return _buildLearningUI(context);
      },
    );
  }

  Widget _buildLearningUI(BuildContext context) {
    final card = cards[index];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            _buildProgressBar(isDark),
            // ĐÃ XÓA: if (showTip) _buildTipCard(),
            
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
            icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : const Color(0xFF1E293B)),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.set.title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
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
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${index + 1}/${cards.length}',
              style: const TextStyle(
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
                    backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${rememberedCards.where((e) => e).length}',
                      style: const TextStyle(
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

  // ĐÃ XÓA: Widget _buildTipCard()

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
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.4),
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
            style: const TextStyle(
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
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.touch_app, color: Colors.white, size: 16),
                SizedBox(width: 8),
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
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF10B981), Color(0xFF059669)],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.4),
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
            style: const TextStyle(
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
            child: const Text(
              'Chạm để lật',
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
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => markAsRemembered(false),
              icon: const Icon(Icons.close_rounded),
              label: const Text('Chưa nhớ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
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
              icon: const Icon(Icons.check_rounded),
              label: const Text('Đã nhớ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
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
    );
  }
}