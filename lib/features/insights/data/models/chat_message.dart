import 'package:flutter/foundation.dart';

enum ChatSender {
  user,
  bot,
}

@immutable
class ChatMessage {
  final String id;
  final String text;
  final ChatSender sender;
  final DateTime timestamp;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
  });

  bool get isUser => sender == ChatSender.user;
}
