import 'package:flutter/material.dart';
// SỬA: Dùng model mới
import '../models/flashcard_set.dart';
import '../models/flashcard.dart';
import '../services/firestore_service.dart';

class FlashcardsScreen extends StatefulWidget {
  // SỬA: Nhận vào FlashcardSet
  final FlashcardSet set;
  const FlashcardsScreen({super.key, required this.set});

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  final FirestoreService _db = FirestoreService();
  int currentIndex = 0;
  bool showMeaning = false;

  void addOrEditFlashcard({Flashcard? card, int? editIndex}) {
    final frontController = TextEditingController(text: card?.english ?? '');
    final backController = TextEditingController(text: card?.vietnamese ?? '');
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(card == null ? 'Thêm flashcard' : 'Sửa flashcard'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: frontController,
              decoration: const InputDecoration(labelText: 'Mặt trước'),
              autofocus: true,
              textInputAction: TextInputAction.next,
            ),
            TextField(
              controller: backController,
              decoration: const InputDecoration(labelText: 'Mặt sau'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Huỷ')),
          ElevatedButton(
            onPressed: () async {
              String front = frontController.text.trim();
              String back = backController.text.trim();
              if (front.isEmpty || back.isEmpty) return;

              try {
                if (card != null && editIndex != null) {
                  await _db.updateFlashcard(
                    widget.set.id, // SỬA
                    card.id,
                    front,
                    back,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã cập nhật thẻ!')));
                } else {
                  await _db.addFlashcard(
                    widget.set.id, // SỬA
                    front,
                    back,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã thêm flashcard mới!')));
                }
              } catch (e) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
              }

              Navigator.pop(ctx);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void deleteFlashcard(Flashcard card) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text('Xác nhận xoá'),
              content: const Text('Bạn có chắc chắn muốn xoá thẻ này?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx), child: const Text('Huỷ')),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await _db.deleteFlashcard(widget.set.id, card.id); // SỬA
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã xoá flashcard!')));
                    } catch (e) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                    }
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                  child: const Text('Xoá'),
                ),
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Flashcard>>(
      stream: _db.getFlashcardsStream(widget.set.id), // SỬA
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: Text(widget.set.title)), // SỬA
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: Text(widget.set.title)), // SỬA
            body: Center(child: Text('Lỗi: ${snapshot.error}')),
          );
        }

        final flashcards = snapshot.data ?? [];

        if (flashcards.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: Text(widget.set.title)), // SỬA
            body: const Center(child: Text('Chủ đề này chưa có flashcard nào.')),
            floatingActionButton: FloatingActionButton(
              onPressed: () => addOrEditFlashcard(),
              child: const Icon(Icons.add),
            ),
          );
        }

        if (currentIndex >= flashcards.length) {
          currentIndex = flashcards.isEmpty ? 0 : flashcards.length - 1;
        }
        
        final card = flashcards[currentIndex];
        
        return Scaffold(
          appBar: AppBar(title: Text(widget.set.title)), // SỬA
          body: Column(
            children: [
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => addOrEditFlashcard(),
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Thêm thẻ mới'),
                    style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16))),
                  ),
                  Tooltip(
                    message: "Quản lý tất cả thẻ",
                    child: ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => Dialog(
                            child: SizedBox(
                              width: 340,
                              height: 420,
                              child: Column(
                                children: [
                                  AppBar(
                                      title: const Text('Tất cả flashcard'),
                                      automaticallyImplyLeading: false),
                                  Expanded(
                                    child: ListView.builder(
                                      itemCount: flashcards.length,
                                      itemBuilder: (ctx, idx) {
                                        final fc = flashcards[idx];
                                        return ListTile(
                                          title: Text(fc.english),
                                          subtitle: Text(fc.vietnamese),
                                          leading: Text('${idx + 1}'),
                                          trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                    icon: const Icon(Icons.edit),
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                      addOrEditFlashcard(
                                                          card: fc,
                                                          editIndex: idx);
                                                    }),
                                                IconButton(
                                                    icon:
                                                        const Icon(Icons.delete),
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                      deleteFlashcard(fc);
                                                    }),
                                              ]),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.menu_book_outlined),
                      label: const Text('Quản lý tất cả'),
                      style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16))),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => showMeaning = !showMeaning);
                    },
                    child: SizedBox(
                      width: 250,
                      height: 150,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 550),
                        transitionBuilder:
                            (Widget child, Animation<double> animation) {
                          // ... (Animation lật thẻ giữ nguyên)
                          final flipAnim =
                              Tween(begin: 0.0, end: 1.0).animate(animation);
                          return AnimatedBuilder(
                            animation: flipAnim,
                            child: child,
                            builder: (context, child) {
                              final isReverse = (showMeaning &&
                                      flipAnim.value < 0.5) ||
                                  (!showMeaning && flipAnim.value > 0.5);
                              final angle =
                                  isReverse ? flipAnim.value - 1 : flipAnim.value;
                              final needsFlip =
                                  showMeaning && flipAnim.value > 0.5;
                              return Transform(
                                transform: Matrix4.identity()
                                  ..setEntry(3, 2, 0.001)
                                  ..rotateY(angle * 3.1416),
                                alignment: Alignment.center,
                                child: Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.identity()
                                    ..scale(needsFlip ? -1.0 : 1.0, 1.0, 1.0),
                                  child: child,
                                ),
                              );
                            },
                          );
                        },
                        layoutBuilder: (widget, list) =>
                            Stack(children: [if (widget != null) widget, ...list]),
                        switchInCurve: Curves.easeInOutBack,
                        switchOutCurve: Curves.easeInOutBack,
                        child: Container(
                          key: ValueKey(showMeaning),
                          decoration: BoxDecoration(
                            color: showMeaning
                                ? Colors.teal[100]
                                : Colors.indigo[100],
                            borderRadius: BorderRadius.circular(16),
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
                            showMeaning ? card.vietnamese : card.english,
                            style: const TextStyle(
                                fontSize: 28, fontWeight: FontWeight.bold),
                            textDirection: TextDirection.ltr,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        currentIndex = (currentIndex - 1 + flashcards.length) %
                            flashcards.length;
                        showMeaning = false;
                      });
                    },
                    child: const Text('← Quay lại'),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        currentIndex = (currentIndex + 1) % flashcards.length;
                        showMeaning = false;
                      });
                    },
                    child: const Text('Tiếp theo →'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
          floatingActionButton: flashcards.isNotEmpty
              ? FloatingActionButton(
                  onPressed: () => addOrEditFlashcard(),
                  child: const Icon(Icons.add),
                )
              : null,
        );
      },
    );
  }
}