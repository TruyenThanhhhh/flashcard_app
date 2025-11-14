import '../models/category.dart';
import '../models/flashcard.dart';
import 'package:uuid/uuid.dart';

final demoCategories = <Category>[
  Category(
    id: const Uuid().v4(),
    name: 'Từ vựng cơ bản',
    cards: [
      Flashcard(id: const Uuid().v4(), english: 'apple', vietnamese: 'quả táo'),
      Flashcard(id: const Uuid().v4(), english: 'book', vietnamese: 'cuốn sách'),
      Flashcard(id: const Uuid().v4(), english: 'car', vietnamese: 'xe hơi'),
      Flashcard(id: const Uuid().v4(), english: 'house', vietnamese: 'ngôi nhà'),
    ],
  ),
  Category(
    id: const Uuid().v4(),
    name: 'Động vật',
    cards: [
      Flashcard(id: const Uuid().v4(), english: 'dog', vietnamese: 'chó'),
      Flashcard(id: const Uuid().v4(), english: 'cat', vietnamese: 'mèo'),
      Flashcard(id: const Uuid().v4(), english: 'cow', vietnamese: 'bò'),
      Flashcard(id: const Uuid().v4(), english: 'bird', vietnamese: 'chim'),
    ],
  ),
  Category(
    id: const Uuid().v4(),
    name: 'Giao tiếp',
    cards: [
      Flashcard(id: const Uuid().v4(), english: 'Hello', vietnamese: 'Xin chào'),
      Flashcard(id: const Uuid().v4(), english: 'Thank you', vietnamese: 'Cảm ơn'),
      Flashcard(id: const Uuid().v4(), english: 'Sorry', vietnamese: 'Xin lỗi'),
    ],
  ),
];
