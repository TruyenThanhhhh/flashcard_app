import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/flashcard.dart';
import '../services/firestore_service.dart'; // SỬA: Dùng FirestoreService
import '../services/auth_service.dart'; // SỬA: Dùng AuthService
import 'quiz_mode_selection_screen.dart';

class QuizScreen extends StatefulWidget {
  final Category category;
  final QuizMode mode;
  const QuizScreen({super.key, required this.category, required this.mode});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late List<Flashcard> cards;
  int current = 0;
  int score = 0;
  bool showResult = false;
  int? selected;
  List<int> questionOrder = [];
  List<List<String>> options = [];
  final rng = UniqueKey();
  // Chuẩn bị dữ liệu quiz khi khởi tạo
  @override
  void initState() {
    super.initState();
    _sessionStartTime = DateTime.now();
    cards = [...widget.category.cards];
    questionOrder = List.generate(cards.length, (i) => i)..shuffle();
    
    // Prepare options for multiple choice mode
    if (widget.mode == QuizMode.multipleChoice) {
      for(final idx in questionOrder) {
        if(cards.length >= 4) {
          // Get 3 wrong answers from other cards
          final correct = cards[idx].vietnamese;
          var wrongs = cards.where((c) => c != cards[idx]).map((c) => c.vietnamese).toList();
          wrongs.shuffle();
          var optionList = wrongs.take(3).toList();
          optionList.add(correct);
          optionList.shuffle();
          options.add(optionList);
        } else {
          // If less than 4 cards, create options by duplicating and shuffling
          final correct = cards[idx].vietnamese;
          var allOptions = cards.map((c) => c.vietnamese).toList();
          // Shuffle and take 4, ensuring correct answer is included
          allOptions.shuffle();
          if (!allOptions.contains(correct)) {
            allOptions[0] = correct;
          }
          var optionList = allOptions.take(4).toList();
          optionList.shuffle();
          options.add(optionList);
        }
      }
    }
  }

  void onSelect(int optionIdx) {
    setState(() { selected = optionIdx; showResult = true; });
    if (options[current][optionIdx] == cards[questionOrder[current]].vietnamese) {
      score++;
    }
    Future.delayed(const Duration(seconds: 1), (){
      if (current < cards.length-1) {
        setState((){ current++; showResult=false; selected=null; });
      } else {
        showQuizSummary();
      }
    });
  }

  // SỬA: Hàm này để gọi service
  Future<void> showQuizSummary() async {
    // Record the learning session
    if (_sessionStartTime != null) {
      final duration = DateTime.now().difference(_sessionStartTime!);
      try {
        await _db.recordQuizSession(
          categoryId: widget.category.id,
          categoryName: widget.category.name,
          duration: duration,
          quizScore: score,
          totalQuestions: cards.length,
        );
      } catch (e) {
        print("Lỗi khi lưu Quiz: $e");
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bạn đã hoàn thành quiz!')),
    );
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hoàn thành Quiz'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Số câu đúng: $score/${cards.length}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height:12),
            Text(score == cards.length ? 'Tuyệt vời! Bạn đạt điểm tối đa!' : 'Tiếp tục luyện tập để nâng cao nhé!'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: (){
              Navigator.of(context)
                ..pop()
                ..pop() // Pop QuizScreen
                ..pop(); // Pop QuizModeSelectionScreen
            },
            child: const Text('OK! Quay lại chủ đề'))
        ],
      ),
    );
  }

  void textAnswer(String ans) {
    setState((){ showResult = true; });
    if(ans.trim().toLowerCase() == cards[questionOrder[current]].vietnamese.trim().toLowerCase()){
      score++;
    }
    Future.delayed(const Duration(milliseconds: 2000), (){
      if (current < cards.length-1) {
        setState((){ current++; showResult=false; });
      } else {
        showQuizSummary();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: const Center(child: Text('Chủ đề chưa có flashcard.')), 
      );
    }
    
    final card = cards[questionOrder[current]];
    final isMultipleChoice = widget.mode == QuizMode.multipleChoice;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz: ${widget.category.name}'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isMultipleChoice ? 'Trắc nghiệm' : 'Điền đáp án',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: isMultipleChoice
        ? _buildMultipleChoiceView(card)
        : QuizTextAnswer(
            card: card,
            show: showResult,
            onAnswer: textAnswer,
            currentQuestion: current + 1,
            totalQuestions: cards.length,
          ),
      ),
      bottomNavigationBar: BottomAppBar(
        elevation: 1,
        child: Container(
          alignment: Alignment.centerRight,
          height: 50,
          child: TextButton.icon(
            onPressed: ()=>Navigator.pop(context),
            icon: const Icon(Icons.home_outlined),
            label: const Text('Về chủ đề'),
          ),
        ),
      ),
    );
  }

  Widget _buildMultipleChoiceView(Flashcard card) {
    final cardOptions = options[current];
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('Câu hỏi ${current+1}/${cards.length}', style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 18),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal:16.0, vertical:20),
            child: Text(card.english, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 30),
        ...List.generate(4, (i) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(230,50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              backgroundColor: showResult
                ? (options[current][i] == card.vietnamese)
                  ? Colors.green
                  : (selected == i ? Colors.red : null)
                : null,
            ),
            onPressed: showResult ? null : () => onSelect(i),
            child: Text(options[current][i], style: const TextStyle(fontSize: 20)),
          ),
        )),
      ],
    );
  }
}

// Lớp QuizTextAnswer không thay đổi
class QuizTextAnswer extends StatefulWidget {
  final Flashcard card;
  final bool show;
  final void Function(String ans) onAnswer;
  final int currentQuestion;
  final int totalQuestions;
  const QuizTextAnswer({
    super.key,
    required this.card,
    required this.show,
    required this.onAnswer,
    required this.currentQuestion,
    required this.totalQuestions,
  });
  @override
  State<QuizTextAnswer> createState() => _QuizTextAnswerState();
}

class _QuizTextAnswerState extends State<QuizTextAnswer> {
  final ctl = TextEditingController();
  bool isCorrect = false;
  
  @override
  void dispose() {
    ctl.dispose();
    super.dispose();
  }
  
  @override
  void didUpdateWidget(QuizTextAnswer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset when moving to next question
    if (oldWidget.show && !widget.show) {
      ctl.clear();
      isCorrect = false;
    }
    // Check answer when result is shown
    if (!oldWidget.show && widget.show && ctl.text.isNotEmpty) {
      isCorrect = ctl.text.trim().toLowerCase() == widget.card.vietnamese.trim().toLowerCase();
    }
  }
  
  void _checkAnswer(String answer) {
    if (answer.trim().isEmpty) return;
    widget.onAnswer(answer);
  }
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Câu hỏi ${widget.currentQuestion}/${widget.totalQuestions}',
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 30),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
              child: Text(
                widget.card.english,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: 300,
            child: TextField(
              controller: ctl,
              enabled: !widget.show,
              decoration: InputDecoration(
                labelText: 'Điền nghĩa tiếng Việt',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
                fillColor: widget.show
                    ? (isCorrect ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1))
                    : null,
              ),
              style: const TextStyle(fontSize: 18),
              onSubmitted: widget.show ? null : (ans) => _checkAnswer(ans),
            ),
          ),
          if (widget.show) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isCorrect ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isCorrect ? Colors.green : Colors.red,
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isCorrect ? Icons.check_circle : Icons.cancel,
                    color: isCorrect ? Colors.green : Colors.red,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isCorrect ? 'Đúng rồi!' : 'Sai rồi!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isCorrect ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            if (!isCorrect) ...[
              const SizedBox(height: 12),
              Text(
                'Đáp án đúng: ${widget.card.vietnamese}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
          if (!widget.show) ...[
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => _checkAnswer(ctl.text),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Trả lời',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ],
      ),
    );
  }
}