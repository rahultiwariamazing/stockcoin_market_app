import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../data/models/chat_message.dart';
import '../data/services/groq_chat_service.dart';

class InsightsChatScreen extends StatefulWidget {
  const InsightsChatScreen({super.key});

  @override
  State<InsightsChatScreen> createState() => _InsightsChatScreenState();
}

class _InsightsChatScreenState extends State<InsightsChatScreen>
  with WidgetsBindingObserver {
  static const List<String> _suggestions = [
    'What is Bitcoin?',
    'How to invest in stocks?',
    'Is crypto safe?',
  ];

  static const List<String> _blockedKeywords = [
    'terrorist',
    'terrorism',
    'bomb',
    'attack',
    'kill',
    'explosive',
    'sex',
    'sexy',
    'porn',
    'nude',
    'romance',
    'romantic',
    'vulgar',
    'adult',
  ];

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GroqChatService _chatService = GroqChatService();

  final List<ChatMessage> _messages = [];
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _messages.add(
      ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        text:
            'Hi, I am your Insights assistant. Ask me about Bitcoin, crypto, stocks, or investing basics.',
        sender: ChatSender.bot,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clearConversation();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      _clearConversation();
    }
  }

  void _clearConversation() {
    _messages.clear();
    _isSending = false;
    _textController.clear();
  }

  bool _containsUnsafeContent(String text) {
    final normalized = text.toLowerCase();
    return _blockedKeywords.any(normalized.contains);
  }

  Future<void> _sendMessage([String? suggestion]) async {
    if (_isSending) return;

    final text = (suggestion ?? _textController.text).trim();
    if (text.isEmpty) return;

    final historyBeforeUser = List<ChatMessage>.from(_messages);

    setState(() {
      _messages.add(
        ChatMessage(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          text: text,
          sender: ChatSender.user,
          timestamp: DateTime.now(),
        ),
      );
      _textController.clear();
    });
    _scrollToBottom();

    if (_containsUnsafeContent(text)) {
      _appendBotMessage(
        'Please keep the chat respectful and avoid violent or sexual content.',
      );
      return;
    }

    setState(() {
      _isSending = true;
    });
    _scrollToBottom();

    final result = await _chatService.fetchReply(
      userMessage: text,
      history: historyBeforeUser,
    );

    if (!mounted) return;

    result.when(
      success: (reply) {
        _appendBotMessage(reply);
      },
      failure: (failure) {
        _appendBotMessage(failure.message);
      },
    );

    if (!mounted) return;
    setState(() {
      _isSending = false;
    });
    _scrollToBottom();
  }

  void _appendBotMessage(String text) {
    if (!mounted) return;

    setState(() {
      _messages.add(
        ChatMessage(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          text: text,
          sender: ChatSender.bot,
          timestamp: DateTime.now(),
        ),
      );
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Insights'),
        elevation: 0,
      ),
      body: Column(
        children: [
          _SuggestionRow(
            suggestions: _suggestions,
            onTap: _sendMessage,
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              itemCount: _messages.length + (_isSending ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isSending && index == _messages.length) {
                  return const _TypingBubble();
                }

                final message = _messages[index];
                return _ChatBubble(message: message);
              },
            ),
          ),
          _InputComposer(
            controller: _textController,
            isLoading: _isSending,
            onSubmit: _sendMessage,
          ),
        ],
      ),
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  final List<String> suggestions;
  final ValueChanged<String> onTap;

  const _SuggestionRow({
    required this.suggestions,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
        itemBuilder: (context, index) {
          final label = suggestions[index];
          return ActionChip(
            label: Text(label),
            onPressed: () => onTap(label),
            backgroundColor: const Color(0xFFEFF3FF),
            side: BorderSide.none,
            labelStyle: const TextStyle(
              color: Color(0xFF1E3A8A),
              fontWeight: FontWeight.w600,
            ),
          );
        },
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemCount: suggestions.length,
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final alignment =
        message.isUser ? Alignment.centerRight : Alignment.centerLeft;
    final radius = message.isUser
        ? const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(6),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(18),
          );

    return Align(
      alignment: alignment,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: message.isUser ? const Color(0xFF1F4BFF) : Colors.white,
          borderRadius: radius,
          border: message.isUser
              ? null
              : Border.all(color: const Color(0xFFE8EDF5), width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A0F172A),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.isUser ? Colors.white : const Color(0xFF101828),
            height: 1.35,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8EDF5), width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x120F172A),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text(
              'Typing...',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF475467),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputComposer extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final Future<void> Function([String?]) onSubmit;

  const _InputComposer({
    required this.controller,
    required this.isLoading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSubmit(),
                decoration: InputDecoration(
                  hintText: 'Ask about Bitcoin, crypto, or stocks...',
                  filled: true,
                  fillColor: const Color(0xFFF3F5FA),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSizes.gapSmall),
            Material(
              color: const Color(0xFF1F4BFF),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: isLoading ? null : () => onSubmit(),
                child: Container(
                  height: 48,
                  width: 48,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.send_rounded,
                    color: isLoading ? Colors.white70 : Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
