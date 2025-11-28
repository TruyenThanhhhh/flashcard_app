import 'package:flutter/material.dart';
import '../models/flashcard_set.dart';
import '../services/firestore_service.dart';
import 'flashcards_screen.dart'; // Để khi bấm vào kết quả thì mở bộ thẻ

class FlashcardSearchDelegate extends SearchDelegate {
  final FirestoreService _db = FirestoreService();

  // 1. Nút xóa (dấu X bên phải thanh tìm kiếm)
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = ''; // Xóa từ khóa
            showSuggestions(context); // Hiện lại gợi ý
          },
        ),
    ];
  }

  // 2. Nút quay lại (mũi tên bên trái)
  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null); // Đóng màn hình tìm kiếm
      },
    );
  }

  // 3. Hiển thị kết quả (khi nhấn Enter) - Ta dùng chung logic với suggestion
  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchList(context);
  }

  // 4. Hiển thị gợi ý (khi đang gõ)
  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchList(context);
  }

  // Hàm chung để hiển thị danh sách
  Widget _buildSearchList(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return StreamBuilder<List<FlashcardSet>>(
      stream: _db.getFlashcardSetsStream(), // Lấy dữ liệu thực từ Firestore
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('Không có dữ liệu', style: TextStyle(color: textColor)));
        }

        final allSets = snapshot.data!;
        
        // LOGIC LỌC: Tìm theo tên chủ đề (không phân biệt hoa thường)
        final filteredSets = allSets.where((set) {
          return set.title.toLowerCase().contains(query.toLowerCase());
        }).toList();

        if (filteredSets.isEmpty) {
           return Center(
             child: Column(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 Icon(Icons.search_off, size: 64, color: Colors.grey),
                 const SizedBox(height: 16),
                 Text(
                   'Không tìm thấy kết quả cho "$query"',
                   style: TextStyle(color: Colors.grey, fontSize: 16),
                 ),
               ],
             ),
           );
        }

        return ListView.builder(
          itemCount: filteredSets.length,
          itemBuilder: (context, index) {
            final set = filteredSets[index];
            return ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(int.tryParse(set.color.replaceFirst('#', '0xFF')) ?? 0xFF4CAF50).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.folder, color: Colors.indigo),
              ),
              title: RichText(
                text: _highlightMatch(set.title, query, textColor),
              ),
              subtitle: Text('${set.cardCount} thẻ', style: const TextStyle(color: Colors.grey)),
              onTap: () {
                // Đóng tìm kiếm và mở màn hình chi tiết
                close(context, null); 
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FlashcardsScreen(set: set),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // Hàm phụ trợ để tô đậm từ khóa tìm thấy
  TextSpan _highlightMatch(String text, String query, Color baseColor) {
    if (query.isEmpty) return TextSpan(text: text, style: TextStyle(color: baseColor));

    List<TextSpan> spans = [];
    int start = 0;
    int indexOfHighlight;
    
    // Chuyển về chữ thường để so sánh vị trí
    String textLower = text.toLowerCase();
    String queryLower = query.toLowerCase();

    while ((indexOfHighlight = textLower.indexOf(queryLower, start)) != -1) {
      if (indexOfHighlight > start) {
        spans.add(TextSpan(
          text: text.substring(start, indexOfHighlight),
          style: TextStyle(color: baseColor),
        ));
      }
      spans.add(TextSpan(
        text: text.substring(indexOfHighlight, indexOfHighlight + query.length),
        style: TextStyle(color: baseColor, fontWeight: FontWeight.bold),
      ));
      start = indexOfHighlight + query.length;
    }

    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: TextStyle(color: baseColor),
      ));
    }

    return TextSpan(children: spans);
  }
}