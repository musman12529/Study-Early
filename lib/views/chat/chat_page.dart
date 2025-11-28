import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/providers/auth_providers.dart';
import '../../controllers/providers/chat_provider.dart';
import '../../controllers/providers/course_providers.dart';
import '../../models/chat_message.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key, required this.courseId});

  final String courseId;

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  static const Color _brandBlue = Color(0xFF1A73E8);
  static const Color _chatBg = Color(0xFFFFF3E8); // light peach
  static const Color _botBubble = Color(0xFFFFE0C2); // bot message
  static const Color _userBubble = Color(0xFFFF7854); // user message
  static const Color _inputBg = Color(0xFFFFF3E8);

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _messageController.clear();
    final authState = ref.read(authStateChangesProvider);
    final user = authState.asData?.value;
    if (user == null) return;

    final chatNotifier = ref.read(
      chatNotifierProvider((user.uid, widget.courseId)).notifier,
    );

    await chatNotifier.sendMessage(message);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
      data: (user) {
        if (user == null) {
          return const Scaffold(body: Center(child: Text('Not logged in')));
        }

        final courseState = ref.watch(courseListProvider(user.uid));
        final course = courseState.firstWhere(
          (c) => c.id == widget.courseId,
          orElse: () => throw Exception('Course not found'),
        );

        final chatState = ref.watch(
          chatNotifierProvider((user.uid, widget.courseId)),
        );

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => Navigator.of(context).pop(),
            ),
            centerTitle: true,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'asset/logo.png',
                  height: 24,
                ),
                const SizedBox(width: 6),
              ],
            ),
            actions: [
              if (chatState.messages.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear_all, color: Colors.black87),
                  tooltip: 'Clear chat',
                  onPressed: () {
                    ref
                        .read(
                          chatNotifierProvider((user.uid, widget.courseId))
                              .notifier,
                        )
                        .clearChat();
                  },
                ),
            ],
          ),
          body: Column(
            children: [
              // Chat header & message list
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: _chatBg,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // "Chatbot" heading
                      const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Text(
                          'Chatbot',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF101828),
                          ),
                        ),
                      ),

                      // Messages list
                      Expanded(
                        child: chatState.messages.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.chat_bubble_outline,
                                      size: 64,
                                      color: Colors.orange[200],
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Start a conversation',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Color(0xFF7A7A7A),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Ask questions about your course materials',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF9E9E9E),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                itemCount: chatState.messages.length +
                                    (chatState.isLoading ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == chatState.messages.length) {
                                    // Loading indicator
                                    return const Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                          SizedBox(width: 16),
                                          Text('Chatbot is thinking...'),
                                        ],
                                      ),
                                    );
                                  }

                                  final message = chatState.messages[index];
                                  return _ChatBubble(
                                    message: message,
                                    botBubbleColor: _botBubble,
                                    userBubbleColor: _userBubble,
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),

              // Error banner (kept, just above input)
              if (chatState.error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: Colors.red[50],
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          chatState.error!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          if (chatState.messages.isNotEmpty &&
                              chatState.messages.last.isUser) {
                            final lastMessage =
                                chatState.messages.last.message;
                            ref
                                .read(
                                  chatNotifierProvider((user.uid, widget.courseId))
                                      .notifier,
                                )
                                .sendMessage(lastMessage);
                          }
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),

              // Input area
              Container(
                color: Colors.white,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _inputBg,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _userBubble.withOpacity(0.7),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              decoration: const InputDecoration(
                                hintText: 'Type a message...',
                                border: InputBorder.none,
                                hintStyle: TextStyle(
                                  color: Color(0xFFEF8C6A),
                                  fontSize: 14,
                                ),
                              ),
                              maxLines: null,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _sendMessage(),
                              enabled: !chatState.isLoading,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap:
                                chatState.isLoading ? null : () => _sendMessage(),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _userBubble,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.send_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.message,
    required this.botBubbleColor,
    required this.userBubbleColor,
  });

  final ChatMessage message;
  final Color botBubbleColor;
  final Color userBubbleColor;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    final bubbleColor = isUser ? userBubbleColor : botBubbleColor;
    final bubbleTextColor = isUser ? Colors.white : const Color(0xFF3D3D3D);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.orange[200],
                child: const Icon(
                  Icons.chat_bubble,
                  size: 18,
                  color: Color(0xFFFF7854),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isUser)
                  const Text(
                    'Chatbot',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFF7854),
                    ),
                  ),
                if (!isUser) const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomRight:
                          isUser ? const Radius.circular(4) : const Radius.circular(16),
                      bottomLeft:
                          !isUser ? const Radius.circular(4) : const Radius.circular(16),
                    ),
                  ),
                  child: Text(
                    message.message,
                    style: TextStyle(
                      color: bubbleTextColor,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // Simple placeholder time – you can wire real timestamps later
                Text(
                  '',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.orange[200],
                child: const Icon(
                  Icons.person,
                  size: 18,
                  color: Color(0xFF6D6D6D),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
