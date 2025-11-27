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

    // Scroll to bottom after message is sent
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
          appBar: AppBar(
            title: Text(course.title),
            actions: [
              if (chatState.messages.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear_all),
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
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Start a conversation',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Ask questions about your course materials',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
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
                                  Text('AI is thinking...'),
                                ],
                              ),
                            );
                          }

                          final message = chatState.messages[index];
                          return _ChatBubble(message: message);
                        },
                      ),
              ),

              // Error message
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
                          // Retry last message if possible
                          if (chatState.messages.isNotEmpty &&
                              chatState.messages.last.isUser) {
                            final lastMessage = chatState.messages.last.message;
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
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: 'Type your message...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            maxLines: null,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendMessage(),
                            enabled: !chatState.isLoading,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed:
                              chatState.isLoading ? null : _sendMessage,
                          icon: const Icon(Icons.send),
                          tooltip: 'Send message',
                        ),
                      ],
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
  const _ChatBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue[100],
              child: Icon(Icons.smart_toy, size: 18, color: Colors.blue[700]),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isUser
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomRight: isUser ? const Radius.circular(4) : null,
                  bottomLeft: !isUser ? const Radius.circular(4) : null,
                ),
              ),
              child: Text(
                message.message,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: Icon(Icons.person, size: 18, color: Colors.grey[700]),
            ),
          ],
        ],
      ),
    );
  }
}

