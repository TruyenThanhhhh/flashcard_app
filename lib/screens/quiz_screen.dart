import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/flashcart.dart';

class QuizScreen extends StatefulWidget {
  final Category category;
  const QuizScreen({super.key, required this.category});

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

  @override
  void initState() {
    super.initState();
    cards = [...widget.category.cards];
    questionOrder = List.generate(cards.length, (i) => i)..shuffle();
    // Chuẩn bị đáp án cho từng câu hỏi (lấy random 3 nghĩa flashcard khác làm choice sai)
    for(final idx in questionOrder) {
      if(cards.length >= 4) {
        final correct = cards[idx].vietnamese;
        var wrongs = cards.where((c) => c != cards[idx]).map((c) => c.vietnamese).toList()..shuffle();
        options.add(((wrongs.take(3).toList()..add(correct))..shuffle()));
      } else {
        options.add([]);
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

  void showQuizSummary() {
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
                ..pop();
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
    Future.delayed(const Duration(milliseconds: 1300), (){
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
    final cardOptions = options[current];
    return Scaffold(
      appBar: AppBar(title: Text('Quiz: ${widget.category.name}')),
      body: Center(
        child: cardOptions.isNotEmpty
        ? Column(
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
            if(showResult)
              Padding(
                padding: const EdgeInsets.all(14),
                child: Text(options[current][selected??0] == card.vietnamese ? 'Đúng!' : 'Sai!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: options[current][selected??0] == card.vietnamese ? Colors.green : Colors.red)),
              ),
          ],
        )
        : QuizTextAnswer(card: card, show: showResult, onAnswer: textAnswer),
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
}

class QuizTextAnswer extends StatefulWidget {
  final Flashcard card;
  final bool show;
  final void Function(String ans) onAnswer;
  const QuizTextAnswer({super.key, required this.card, required this.show, required this.onAnswer});
  @override
  State<QuizTextAnswer> createState() => _QuizTextAnswerState();
}
class _QuizTextAnswerState extends State<QuizTextAnswer> {
  final ctl = TextEditingController();
  bool done = false;
  @override
  void dispose(){ ctl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top:80.0),
      child: Column(
        children: [
          Text(widget.card.english, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height:30),
          SizedBox(
            width: 280,
            child: TextField(
              controller: ctl,
              enabled: !widget.show,
              decoration: const InputDecoration(labelText: 'Điền nghĩa tiếng Việt'),
              onSubmitted: widget.show ? null : (ans){
                setState(()=>done=true);
                widget.onAnswer(ans);
              },
            ),
          ),
          const SizedBox(height:20),
          ElevatedButton(
            onPressed: widget.show ? null : () {
              setState(()=>done=true);
              widget.onAnswer(ctl.text);
            },
            child: const Text('Trả lời'),
          ),
          if(widget.show)
            Padding(
              padding: const EdgeInsets.all(14),
              child: Text(ctl.text.trim().toLowerCase() == widget.card.vietnamese.trim().toLowerCase() ? 'Đúng!' : 'Sai!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: ctl.text.trim().toLowerCase() == widget.card.vietnamese.trim().toLowerCase() ? Colors.green : Colors.red)),
            ),
        ],
      ),
    );
  }
}
