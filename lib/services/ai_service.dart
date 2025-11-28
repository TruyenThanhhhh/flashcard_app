import 'dart:convert';
import 'package:http/http.dart' as http;

class AiService {
  final String _apiKey = 'AIzaSyCnVgMuLtzYmWtfSNIs_ubBX0zFQOXcBEA'; 

  Future<List<String>> generateWrongAnswers(String term, String definition) async {
    if (_apiKey.isEmpty) {
      return ["(Thiếu Key)", "Vui lòng nhập Key", "vào ai_service.dart"];
    }

    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-09-2025:generateContent?key=${_apiKey.trim()}');

    // CẢI TIẾN PROMPT: Yêu cầu AI "bắt chước" phong cách của đáp án đúng
    final prompt = '''
      Act as an expert quiz creator. I need 3 incorrect options (distractors) for a multiple-choice question.
      
      The Correct Answer is: "$term"
      The Context/Definition is: "$definition"
      
      STRICT RULES FOR DISTRACTORS:
      1. **Same Category:** If the answer is a Planet, distractors must be other Planets. If it's an Animal, distractors must be Animals.
      2. **Same Style:** If the answer is a short noun (e.g., "Mars"), distractors must be short nouns (e.g., "Venus"). If it's a descriptive phrase (e.g., "The hottest planet"), distractors must be descriptive phrases (e.g., "The coldest planet").
      3. **Plausible:** They must sound reasonable to a learner but be factually WRONG based on the definition.
      4. **Language:** Output in the SAME LANGUAGE as the Correct Answer ("$term").
      
      OUTPUT FORMAT:
      - Strictly a JSON Array of 3 strings.
      - Example: ["Option A", "Option B", "Option C"]
    ''';

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [{
            "parts": [{ "text": prompt }]
          }],
          "generationConfig": {
            "response_mime_type": "application/json"
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String textResult = data['candidates'][0]['content']['parts'][0]['text'];
        textResult = textResult.replaceAll('```json', '').replaceAll('```', '').trim();
        
        List<dynamic> jsonList = jsonDecode(textResult);
        return jsonList.map((e) => e.toString()).toList();
      } else {
        print("Lỗi API ${response.statusCode}: ${response.body}");
        return ["Lỗi ${response.statusCode}", "Thử lại sau", "Đáp án mẫu"];
      }
    } catch (e) {
      print("Lỗi kết nối: $e");
      return ["Lỗi kết nối", "Kiểm tra mạng", "Đáp án mẫu"];
    }
  }
}