import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/flashcart.dart';
import 'package:uuid/uuid.dart';

class FlashcardsScreen extends StatefulWidget {
  final Category category;
  const FlashcardsScreen({super.key, required this.category});

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  late List<Flashcard> flashcards;
  int currentIndex = 0;
  bool showMeaning = false;

  @override
  void initState() {
    super.initState();
    flashcards = [...widget.category.cards];
  }

  void addOrEditFlashcard({Flashcard? card, int? editIndex}) {
    final enController = TextEditingController(text: card?.english ?? '');
    final viController = TextEditingController(text: card?.vietnamese ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(card == null ? 'Thêm flashcard' : 'Sửa flashcard'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: enController,
              decoration: const InputDecoration(labelText: 'Từ tiếng Anh'),
              autofocus: true,
              textInputAction: TextInputAction.next,
            ),
            TextField(
              controller: viController,
              decoration: const InputDecoration(labelText: 'Nghĩa tiếng Việt'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Huỷ')), 
          ElevatedButton(
            onPressed: () {
              String en = enController.text.trim();
              String vi = viController.text.trim();
              if (en.isEmpty || vi.isEmpty) return;
              setState(() {
                if (card != null && editIndex != null) {
                  flashcards[editIndex] = Flashcard(id: card.id, english: en, vietnamese: vi);
                } else {
                  flashcards.add(Flashcard(id: const Uuid().v4(), english: en, vietnamese: vi));
                }
                currentIndex = flashcards.length - 1;
                showMeaning = false;
              });
              Navigator.pop(ctx);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void deleteFlashcard(int idx) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xoá'),
        content: const Text('Bạn có chắc chắn muốn xoá thẻ này?'),
        actions: [
          TextButton(onPressed:()=>Navigator.pop(ctx), child: const Text('Huỷ')), 
          ElevatedButton(
              onPressed: (){
                setState(() {
                  flashcards.removeAt(idx);
                  if (currentIndex >= flashcards.length) {
                    currentIndex = flashcards.isEmpty ? 0 : flashcards.length - 1;
                  }
                  showMeaning = false;
                });
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Xoá'),
          ),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
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
    final card = flashcards[currentIndex];
    return Scaffold(
      appBar: AppBar(title: Text(widget.category.name)),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => addOrEditFlashcard(),
                icon: const Icon(Icons.add),
                label: const Text('Thêm thẻ mới'),
              ),
              ElevatedButton.icon(
                onPressed: () { 
                  showDialog(
                    context: context,
                    builder: (ctx) => Dialog(
                      child: SizedBox(
                        width: 340,
                        height: 420,
                        child: Column(
                          children: [
                            AppBar(title: const Text('Tất cả flashcard'), automaticallyImplyLeading: false),
                            Expanded(
                              child: ListView.builder(
                                itemCount: flashcards.length,
                                itemBuilder: (ctx, idx) {
                                  final fc = flashcards[idx];
                                  return ListTile(
                                    title: Text(fc.english),
                                    subtitle: Text(fc.vietnamese),
                                    leading: Text('${idx+1}'),
                                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: (){
                                          Navigator.pop(context); 
                                          addOrEditFlashcard(card: fc, editIndex: idx);
                                        }),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: (){
                                          Navigator.pop(context);
                                          deleteFlashcard(idx);
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
                icon: const Icon(Icons.list),
                label: const Text('Quản lý tất cả'),
              )
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: () {
                  setState(() => showMeaning = !showMeaning);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: 250,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.indigo[100],
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
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: (){
                  setState(() {
                    currentIndex = (currentIndex - 1 + flashcards.length) % flashcards.length;
                    showMeaning = false;
                  });
                },
                child: const Text('← Quay lại'),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: (){
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
  }
}
