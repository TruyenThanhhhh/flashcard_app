import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/flashcart.dart';

class LearningScreen extends StatefulWidget {
  final Category category;
  const LearningScreen({super.key, required this.category});

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  late List<Flashcard> cards;
  late List<bool> rememberedCards;
  int index = 0;
  bool showAnswer = false;

  @override
  void initState() {
    super.initState();
    cards = [...widget.category.cards];
    rememberedCards = List.filled(cards.length, false);
  }

  void markAsRemembered(bool remembered) {
    setState(() {
      rememberedCards[index] = remembered;
      if (index < cards.length - 1) {
        index++;
        showAnswer = false;
      } else {
        // Học xong tất cả các thẻ
        Future.delayed(const Duration(milliseconds: 200), () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Hoàn thành'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Bạn đã học xong tất cả flashcard.'),
                  Text('Đã nhớ:  ${rememberedCards.where((e)=>e).length}/${cards.length} thẻ'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: (){
                    Navigator.of(context)
                        ..pop()
                        ..pop(); // Quay lại chủ đề
                  },
                  child: const Text('OK'))
              ],
            ),
          );
        });
      }
    });
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
    return Scaffold(
      appBar: AppBar(title: Text('Chế độ học: ${widget.category.name}')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${index+1}/${cards.length}', style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => setState(() => showAnswer = !showAnswer),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 280,
                height: 160,
                decoration: BoxDecoration(
                  color: showAnswer ? Colors.teal[100] : Colors.indigo[100],
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  showAnswer ? card.vietnamese : card.english,
                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.visibility),
                  label: Text(showAnswer ? 'Ẩn nghĩa' : 'Xoay thẻ'),
                  onPressed: () => setState(() => showAnswer = !showAnswer),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[700],
                  ),
                ),
                const SizedBox(width: 18),
                ElevatedButton(
                  onPressed: () => markAsRemembered(true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Đã nhớ'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => markAsRemembered(false),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Chưa nhớ'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
