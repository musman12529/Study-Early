import 'package:uuid/uuid.dart';

class ChatMessage {
  final String id;
  final String message;
  final bool isUser;
  final DateTime timestamp;
  final String? messageId; // OpenAI message ID for tracking

  ChatMessage({
    String? id,
    required this.message,
    required this.isUser,
    DateTime? timestamp,
    this.messageId,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'message': message,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'messageId': messageId,
    };
  }

  static ChatMessage fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'],
      message: map['message'],
      isUser: map['isUser'] ?? false,
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'])
          : null,
      messageId: map['messageId'],
    );
  }

  ChatMessage copyWith({
    String? id,
    String? message,
    bool? isUser,
    DateTime? timestamp,
    String? messageId,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      message: message ?? this.message,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      messageId: messageId ?? this.messageId,
    );
  }
}

