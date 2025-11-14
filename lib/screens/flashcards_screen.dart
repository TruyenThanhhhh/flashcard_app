// lib/screens/flashcard_screen.dart

import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/flashcard.dart';
import '../services/firestore_service.dart'; // Giữ nguyên

class FlashcardsScreen extends StatefulWidget {
  final Category category;
  const FlashcardsScreen({super.key, required this.category});

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  final FirestoreService _db = FirestoreService();
  int currentIndex = 0;
  bool showMeaning = false;

  void addOrEditFlashcard({Flashcard? card, int? editIndex}) {
    // SỬA: Đổi tên biến để khớp với DB (front/back)
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
              controller: frontController, // Sửa
              decoration: const InputDecoration(labelText: 'Mặt trước (Tiếng Anh)'),
              autofocus: true,
              textInputAction: TextInputAction.next,
            ),
            TextField(
              controller: backController, // Sửa
              decoration: const InputDecoration(labelText: 'Mặt sau (Nghĩa)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Huỷ')),
          ElevatedButton(
            onPressed: () async {
              String front = frontController.text.trim(); // Sửa
              String back = backController.text.trim();  // Sửa
              if (front.isEmpty || back.isEmpty) return;

              try {
                if (card != null && editIndex != null) {
                  // SỬA: Gọi service Sửa
                  await _db.updateFlashcard(
                    widget.category.id, // Đây là flashcardSetId
                    card.id,
                    front,
                    back,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã cập nhật thẻ!')));
                } else {
                  // SỬA: Gọi service Thêm
                  await _db.addFlashcard(
                    widget.category.id, // Đây là flashcardSetId
                    front,
                    back,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã thêm flashcard mới!')));
                }
                // Không cần setState vì StreamBuilder sẽ tự cập nhật
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
                      // SỬA: Gọi service Xóa
                      await _db.deleteFlashcard(widget.category.id, card.id);
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
      //
      // ===================================================================
      // SỬA LỖI QUAN TRỌNG NHẤT:
      // Dùng hàm trả về Stream (getFlashcardsStream)
      // thay vì hàm trả về Future (getFlashcardsForCategory)
      // ===================================================================
      //
      stream: _db.getFlashcardsStream(widget.category.id),
      //
      //
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: Text(widget.category.name)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: Text(widget.category.name)),
            body: Center(child: Text('Lỗi: ${snapshot.error}')),
          );
        }

        final flashcards = snapshot.data ?? [];

        if (flashcards.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: Text(widget.category.name)),
            body: const Center(child: Text('Chủ đề này chưa có flashcard nào.')),
            floatingActionButton: FloatingActionButton(
              onPressed: () => addOrEditFlashcard(),
              child: const Icon(Icons.add),
            ),
          );
        }

        // Đảm bảo currentIndex không bị lỗi
        if (currentIndex >= flashcards.length) {
          currentIndex = flashcards.isEmpty ? 0 : flashcards.length - 1;
        }

        final card = flashcards[currentIndex];

        return Scaffold(
          appBar: AppBar(title: Text(widget.category.name)),
          body: Column(
            children: [
              // ... (Phần nút 'Thêm thẻ mới' và 'Quản lý' giữ nguyên) ...
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

              // ... (Phần GestureDetector và AnimatedSwitcher lật thẻ giữ nguyên) ...
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
                            showMeaning ? card.vietnamese : card.english, // Giữ nguyên
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

              // ... (Phần nút Quay lại / Tiếp theo giữ nguyên) ...
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