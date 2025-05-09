import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;

Future<String> callGPTApi(String userMessage) async {
  final apiKey = dotenv.env['OPENAI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    throw Exception('API Key not found in .env');
  }

  const apiUrl = 'https://api.openai.com/v1/chat/completions';

  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $apiKey',
  };

  final body = jsonEncode({
    "model": "gpt-4.1-nano",
    "messages": [
      {"role": "system", "content": "너는 자전거 대리점 사장님이야. 너와 대화할 때는 전화통화 상황이라고 생각하고, 질문에 사장님처럼 대답해. 존댓말을 쓸 필요 없고 마치 친구한테 답변하듯 대화해줘. 가급적이면 한번 했던 말들은 반복해서 답변하지 않도록 해줘. 예산이 부족하거나, 무리한 질문을 할 경우에는 과감하게 조언해도 돼."},
      {"role": "user", "content": userMessage}
    ],
    "max_tokens": 1000,
    "temperature": 0.8,
  });

  final response = await http.post(
    Uri.parse(apiUrl),
    headers: headers,
    body: body,
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final reply = data['choices'][0]['message']['content'];
    return reply.trim();
  } else {
    throw Exception('API 호출 실패: ${response.statusCode} ${response.body}');
  }
}

class Tts {
  static final tts = FlutterTts();
  static Future<void> speak(String text) async {

    await tts.setLanguage('ko-KR');
    await tts.setPitch(1.0);
    await tts.setSpeechRate(0.5);
    await tts.speak(text);

  }
}