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
  bool showTip = true;

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
        Future.delayed(const Duration(milliseconds: 200), () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Học xong chủ đề!')),
          );
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
                        ..pop();
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
            if (showTip)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Card(
                  color: Colors.amber[50],
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.touch_app, color: Colors.amber),
                    title: const Text('Chạm vào thẻ để lật nghĩa!'),
                    trailing: IconButton(icon:const Icon(Icons.close),onPressed:(){setState(()=>showTip=false);}),
                  ),
                ),
              ),
            GestureDetector(
              onTap: () { setState((){ showAnswer = !showAnswer; showTip=false; }); },
              child: SizedBox(
                width: 280,
                height: 160,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 550),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    final flipAnim = Tween(begin: 0.0, end: 1.0).animate(animation);
                    return AnimatedBuilder(
                      animation: flipAnim,
                      child: child,
                      builder: (context, child) {
                        final isReverse = (showAnswer && flipAnim.value < 0.5) || (!showAnswer && flipAnim.value > 0.5);
                        final angle = isReverse ? flipAnim.value - 1 : flipAnim.value;
                        return Transform(
                          transform: Matrix4.identity()..setEntry(3, 2, 0.001)
                            ..rotateY(angle * 3.1416),
                          alignment: Alignment.center,
                          child: child,
                        );
                      },
                    );
                  },
                  layoutBuilder: (widget, list) => Stack(children: [if (widget != null) widget, ...list]),
                  switchInCurve: Curves.easeInOutBack,
                  switchOutCurve: Curves.easeInOutBack,
                  child: Container(
                    key: ValueKey(showAnswer),
                    decoration: BoxDecoration(
                      color: showAnswer ? Colors.teal[100] : Colors.indigo[100],
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(2,2),
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
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Tooltip(
                  message: showAnswer ? 'Ẩn nghĩa' : 'Xoay thẻ',
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.visibility),
                    label: Text(showAnswer ? 'Ẩn nghĩa' : 'Xoay thẻ'),
                    onPressed: () => setState(() => showAnswer = !showAnswer),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[700],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Tooltip(
                  message: 'Đánh dấu đã nhớ',
                  child: ElevatedButton(
                    onPressed: () => markAsRemembered(true),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape:RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: const Text('Đã nhớ'),
                  ),
                ),
                const SizedBox(width: 12),
                Tooltip(
                  message: 'Nhấn nếu cần ôn lại từ này',
                  child: ElevatedButton(
                    onPressed: () => markAsRemembered(false),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: const Text('Chưa nhớ'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
