import 'package:cloud_functions/cloud_functions.dart';

class ChatService {
  Future<ChatResponse> sendMessage({
    required String userId,
    required String courseId,
    required String message,
    List<ChatMessageHistory>? conversationHistory,
  }) async {
    try {
      final result = await FirebaseFunctions.instanceFor(
        region: 'northamerica-northeast2',
      ).httpsCallable('chatWithCourse').call({
        'userId': userId,
        'courseId': courseId,
        'message': message,
        'conversationHistory': conversationHistory?.map((msg) => {
              'role': msg.role,
              'content': msg.content,
            }).toList(),
      });

      final data = result.data as Map<String, dynamic>;
      return ChatResponse(
        response: data['response'] as String,
        messageId: data['messageId'] as String?,
      );
    } catch (e) {
      throw ChatException('Failed to send message: ${e.toString()}');
    }
  }
}

class ChatResponse {
  final String response;
  final String? messageId;

  ChatResponse({
    required this.response,
    this.messageId,
  });
}

class ChatException implements Exception {
  final String message;
  ChatException(this.message);

  @override
  String toString() => message;
}

class ChatMessageHistory {
  final String role; // 'user' or 'assistant'
  final String content;

  ChatMessageHistory({
    required this.role,
    required this.content,
  });
}

