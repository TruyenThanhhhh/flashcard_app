import 'package:flutter/material.dart';
import '../models/flashcard.dart';
import '../models/flashcard_set.dart';
import '../services/firestore_service.dart';
import '../services/ai_service.dart';
import 'quiz_mode_selection_screen.dart';

class QuizScreen extends StatefulWidget {
  final FlashcardSet set;
  final QuizMode mode;

  const QuizScreen({super.key, required this.set, required this.mode});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final FirestoreService _db = FirestoreService();
  final AiService _aiService = AiService();

  List<Flashcard> _cards = [];
  bool _isLoading = true;

  int _currentIndex = 0;
  int _score = 0;
  bool _isAnswered = false;

  // Trắc nghiệm
  List<String> _currentOptions = [];
  String? _selectedAnswer;
  bool _isGeneratingOptions = false;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    List<Flashcard> loadedCards = await _db.getFlashcardsOnce(
      widget.set.id,
      userId: widget.set.isPublic ? widget.set.userId : null,
    );

    loadedCards.shuffle();

    if (mounted) {
      setState(() {
        _cards = loadedCards;
        _isLoading = false;
      });

      if (_cards.isNotEmpty && widget.mode == QuizMode.multipleChoice) {
        _prepareOptionsForCurrentQuestion();
      }
    }
  }

  Future<void> _prepareOptionsForCurrentQuestion() async {
    setState(() {
      _isGeneratingOptions = true;
      _currentOptions = [];
      _isAnswered = false;
      _selectedAnswer = null;
    });

    final currentCard = _cards[_currentIndex];
    
    // LOGIC ĐÚNG: Đáp án đúng là từ Tiếng Anh (English)
    final correctAnswer = currentCard.english; 
    List<String> wrongAnswers = [];

    // Nếu bộ thẻ có đủ 4 từ trở lên -> Lấy random từ khác làm đáp án sai (Nhanh)
    if (_cards.length >= 4) {
      final otherCards = List<Flashcard>.from(_cards)..removeAt(_currentIndex);
      otherCards.shuffle();
      wrongAnswers = otherCards.take(3).map((e) => e.english).toList();
    } 
    // Nếu ít thẻ -> Gọi AI tạo đáp án sai (Thông minh)
    else {
      wrongAnswers = await _aiService.generateWrongAnswers(currentCard.english, currentCard.vietnamese);
    }

    // Gộp và xáo trộn
    List<String> options = [...wrongAnswers, correctAnswer];
    options.shuffle();

    if (mounted) {
      setState(() {
        _currentOptions = options;
        _isGeneratingOptions = false;
      });
    }
  }

  void _handleAnswer(String answer) {
    if (_isAnswered) return;

    final correctCard = _cards[_currentIndex];
    final isCorrect = answer.trim().toLowerCase() == correctCard.english.trim().toLowerCase();

    setState(() {
      _isAnswered = true;
      _selectedAnswer = answer;
      if (isCorrect) _score++;
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        if (_currentIndex < _cards.length - 1) {
          setState(() {
            _currentIndex++;
            _isAnswered = false;
            _selectedAnswer = null;
          });
          if (widget.mode == QuizMode.multipleChoice) {
            _prepareOptionsForCurrentQuestion();
          }
        } else {
          _showResultDialog();
        }
      }
    });
  }

  void _showResultDialog() {
    _db.recordQuizSession(
      categoryId: widget.set.id,
      categoryName: widget.set.title,
      duration: const Duration(minutes: 1),
      quizScore: _score,
      totalQuestions: _cards.length,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Kết quả Quiz"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, color: Colors.amber, size: 60),
            const SizedBox(height: 16),
            Text("Đúng $_score/${_cards.length} câu", 
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text("Kết thúc"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _currentIndex = 0;
                _score = 0;
                _isLoading = true;
              });
              _loadCards();
            },
            child: const Text("Làm lại"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.set.title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_cards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.set.title)),
        body: const Center(child: Text("Không có thẻ nào!")),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.grey[100],
      appBar: AppBar(
        title: Text("Quiz: ${widget.set.title}"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (_currentIndex + 1) / _cards.length,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation(Colors.indigo),
              minHeight: 6,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text("Câu hỏi ${_currentIndex + 1}/${_cards.length}",
                      style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                    const SizedBox(height: 20),
                    
                    // --- HIỂN THỊ CÂU HỎI (TIẾNG VIỆT) ---
                    _buildQuestionCard(isDark),
                    
                    const SizedBox(height: 30),
                    
                    if (widget.mode == QuizMode.multipleChoice)
                      _buildMultipleChoiceArea()
                    else
                      _buildTextAnswerArea(isDark),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(bool isDark) {
    final currentCard = _cards[_currentIndex];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          const Text("Thuật ngữ của:", 
            style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 15),
          // HIỂN THỊ NGHĨA TIẾNG VIỆT
          Text(
            currentCard.vietnamese, 
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24, 
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultipleChoiceArea() {
    if (_isGeneratingOptions) {
      return const Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 10),
            Text("AI đang tạo đáp án...", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    final correctAnswer = _cards[_currentIndex].english;

    return Column(
      children: List.generate(_currentOptions.length, (i) {
        final option = _currentOptions[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildOptionButton(option, correctAnswer),
        );
      }),
    );
  }

  Widget _buildOptionButton(String option, String correctAnswer) {
    Color backgroundColor = Colors.white;
    Color borderColor = Colors.grey.shade300;
    Color textColor = Colors.black87;

    if (_isAnswered) {
      if (option == correctAnswer) {
        backgroundColor = Colors.green.shade100;
        borderColor = Colors.green;
        textColor = Colors.green.shade800;
      } else if (option == _selectedAnswer) {
        backgroundColor = Colors.red.shade100;
        borderColor = Colors.red;
        textColor = Colors.red.shade800;
      }
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isAnswered ? null : () => _handleAnswer(option),
        borderRadius: BorderRadius.circular(15),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(option, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
              ),
              if (_isAnswered && option == correctAnswer)
                const Icon(Icons.check_circle, color: Colors.green),
              if (_isAnswered && option == _selectedAnswer && option != correctAnswer)
                const Icon(Icons.cancel, color: Colors.red),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextAnswerArea(bool isDark) {
    return QuizTextAnswer(
      card: _cards[_currentIndex],
      show: _isAnswered,
      onAnswer: _handleAnswer,
      isCorrect: _selectedAnswer != null && 
                 _selectedAnswer!.trim().toLowerCase() == _cards[_currentIndex].english.trim().toLowerCase(),
    );
  }
}

class QuizTextAnswer extends StatefulWidget {
  final Flashcard card;
  final bool show;
  final bool isCorrect;
  final void Function(String ans) onAnswer;

  const QuizTextAnswer({
    super.key, required this.card, required this.show, required this.onAnswer, this.isCorrect = false,
  });

  @override
  State<QuizTextAnswer> createState() => _QuizTextAnswerState();
}

class _QuizTextAnswerState extends State<QuizTextAnswer> {
  final TextEditingController _controller = TextEditingController();

  @override
  void didUpdateWidget(QuizTextAnswer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.show && !widget.show) _controller.clear();
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  void _submit() {
    if (_controller.text.trim().isEmpty) return;
    widget.onAnswer(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        TextField(
          controller: _controller,
          enabled: !widget.show,
          style: TextStyle(fontSize: 18, color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            labelText: 'Nhập đáp án',
            labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            filled: true,
            fillColor: widget.show
                ? (widget.isCorrect ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1))
                : (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
            suffixIcon: widget.show
                ? Icon(widget.isCorrect ? Icons.check_circle : Icons.cancel, color: widget.isCorrect ? Colors.green : Colors.red)
                : null,
          ),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 20),
        if (widget.show) ...[
          // Kết quả
           Text(widget.isCorrect ? "Chính xác!" : "Đáp án đúng: ${widget.card.english}",
             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: widget.isCorrect ? Colors.green : Colors.red)),
        ] else ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: Colors.indigo, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: const Text('Trả lời', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ],
    );
  }
}