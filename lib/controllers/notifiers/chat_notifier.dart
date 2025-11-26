import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/chat_message.dart';
import '../services/chat_service.dart' show ChatService, ChatMessageHistory;

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier({
    required String userId,
    required String courseId,
    required ChatService chatService,
  })  : _userId = userId,
        _courseId = courseId,
        _chatService = chatService,
        super(const ChatState());

  final String _userId;
  final String _courseId;
  final ChatService _chatService;

  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    // Add user message to state immediately
    final userMessage = ChatMessage(
      message: message.trim(),
      isUser: true,
    );
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      error: null,
    );

    try {
      // Build conversation history from previous messages
      final conversationHistory = state.messages
          .map((msg) => ChatMessageHistory(
                role: msg.isUser ? 'user' : 'assistant',
                content: msg.message,
              ))
          .toList();

      // Call the chat service
      final response = await _chatService.sendMessage(
        userId: _userId,
        courseId: _courseId,
        message: message.trim(),
        conversationHistory: conversationHistory,
      );

      // Add AI response to state
      final aiMessage = ChatMessage(
        message: response.response,
        isUser: false,
        messageId: response.messageId,
      );

      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void clearChat() {
    state = const ChatState();
  }
}

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

