import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/chat_service.dart';
import '../notifiers/chat_notifier.dart';

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService();
});

final chatNotifierProvider = StateNotifierProvider.family<
    ChatNotifier, ChatState, (String userId, String courseId)>((ref, args) {
  final userId = args.$1;
  final courseId = args.$2;
  final chatService = ref.watch(chatServiceProvider);

  return ChatNotifier(
    userId: userId,
    courseId: courseId,
    chatService: chatService,
  );
});

